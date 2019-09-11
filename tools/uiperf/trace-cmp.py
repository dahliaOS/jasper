#!/usr/bin/env python3
#
# Copyright 2018 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.
"""
"""

import argparse
import collections
import json
import sys

try:
  import matplotlib.patches
  import matplotlib.pyplot as plt
  import numpy as np
  import pandas as pd
  import scipy as sp
  import scipy.stats
  import seaborn as sns
  plt.style.use('ggplot')
except ImportError as e:
  print("""\
Looks like you didn't have one of the following libraries installed:
  * matplotlib
  * numpy
  * pandas
  * scipy
  * seaborn
Try installing them with:
  $ sudo apt install python3-matplotlib python3-numpy python3-pandas python3-scipy python3-seaborn""")
  raise e

parser = argparse.ArgumentParser(
    description="""\
Compare the distribution of event durations between two (groups of) trace files.

Example usage:
  ./topaz/tools/uiperf/trace-cmp.py \\
    --event_name 'vsync callback' \\
    --thread_names 'assistant_card_image_grid.ui' \\
    --before trace-2018-10-09T21:00:25.json trace-2018-10-09T21:08:14.json \\
    --after trace-2018-10-09T21:12:14.json trace-2018-10-09T22:03:04.json
""",
    formatter_class=argparse.RawDescriptionHelpFormatter)

parser.add_argument(
    '--event_name',
    default='vsync callback',
    nargs='?',
    help=
    'What event name to look for in each trace.  By default, this is '
    '\'vsync callback\', which is the total per frame workload on the Flutter '
    'UI thread.'
)
parser.add_argument(
    '--thread_names',
    default=[],
    nargs='*',
    help=
    'What thread names to search for |event_name| in.  Example: "dashboard.ui".'
)
parser.add_argument(
    '--before',
    default=[],
    nargs='+',
    help=
    'A list of before (a build without your changes) json trace files.  Example: "trace-2018-10-09T22:18:26.json".'
)
parser.add_argument(
    '--after',
    default=[],
    nargs='+',
    help=
    'A list of after (a build with your changes) json trace files.  Example: "trace-2018-10-09T22:25:01.json".'
)
# TODO: Add cdf as a graph option.
valid_graph_args = {'none', 'density'}
parser.add_argument(
    '--graph',
    default='none',
    nargs='?',
    help='Optionally display a density plot of the distribution of event durations.  Must be one of {}'.format(valid_graph_args)
)

args = parser.parse_args()

target_event_name = args.event_name
target_thread_names = set(args.thread_names)
before_filenames = args.before
after_filenames = args.after

if len(before_filenames) == 0:
  print('List of before tracefiles must be non-empty.')
  parser.print_usage()
  sys.exit(1)
if len(after_filenames) == 0:
  parser.print_usage()
  print('List of after tracefiles must be non-empty.')
  sys.exit(1)

if args.graph not in valid_graph_args:
  parser.print_usage()
  print('Invalid --graph argument, must be one of {}'.format(valid_graph_args))
  sys.exit(1)

# {
#   pthread:0x1234: {'Before': [e0, e1, ...], 'After': [e0, e1, ...]},
#   pthread:0x1235: {'Before': [e0, e1, ...], 'After': [e0, e1, ...]},
# }
thread_name_to_groups = collections.defaultdict(
    lambda: collections.defaultdict(list))

for group, filenames in [('Before', before_filenames), ('After',
                                                        after_filenames)]:
  for filename in filenames:
    with open(filename) as f:
      root_object = json.load(f)

    system_trace_events = root_object['systemTraceEvents']
    trace_events = root_object['traceEvents']

    # A mapping of thread ids to thread names.
    tid_to_name = {}
    for e in system_trace_events['events']:
      if e['ph'] == 't':
        tid_to_name[e['tid']] = e['name']

    # Group (events sorted by ts) by tid.
    by_tid = collections.defaultdict(list)
    for e in trace_events:
      by_tid[e['tid']].append(e)
    for k, v in by_tid.items():
      by_tid[k] = sorted(v, key=lambda e: e['ts'])

    for tid, es in by_tid.items():
      thread_name = tid_to_name[tid]
      if len(
          target_thread_names) > 0 and thread_name not in target_thread_names:
        continue

      events = [e for e in es if e['name'] == target_event_name]
      event_durations = []
      begin_stack = []
      # If the first event's phase is end, then remove it.
      if len(events) > 0 and events[0]['ph'] == 'E':
        events.pop(0)
      for e in events:
        if e['ph'] == 'B':
          begin_stack.append(e)
        elif e['ph'] == 'E':
          popped = begin_stack.pop()
          event_durations.append(e['ts'] - popped['ts'])
        else:
          assert False
      assert len(begin_stack) == 0

      if len(event_durations) == 0:
        continue

      thread_name_to_groups[thread_name][group].append(event_durations)

for thread_name, groups in thread_name_to_groups.items():
  if ('Before' in groups) ^ ('After' in groups):
    print('Found thread name "{}" only in {} trace'.format(
        thread_name, ['Before', 'After']['After' in groups]))
  df = pd.DataFrame(columns=[
      'Group',
      'Count',
      # https://en.wikipedia.org/wiki/Sample_maximum_and_minimum
      'Minimum',
      # https://en.wikipedia.org/wiki/Percentile
      '25th Percentile',
      # https://en.wikipedia.org/wiki/Median
      'Median',
      # https://en.wikipedia.org/wiki/Sample_mean_and_covariance
      'Mean',
      '75th Percentile',
      '90th Percentile',
      '95th Percentile',
      '99th Percentile',
      'Maximum',
      # https://en.wikipedia.org/wiki/Standard_deviation#Sample_standard_deviation
      'Standard Deviation',
      # https://en.wikipedia.org/wiki/Median_absolute_deviation
      'Median Absolute Deviation',
      # https://en.wikipedia.org/wiki/Outlier#Tukey's_fences
      'Tukey Outlier Count',
  ])
  yss = []
  for key in ['Before', 'After']:
    group = groups[key]
    ys = []
    for item in group:
      ys += item
    ys = np.array(ys)
    yss.append(ys)
    color = {
        'Before': 'blue',
        'After': 'orange',
    }[key]
    sns.distplot(ys, rug=True, color=color, label=key, bins=20)

    row = {}
    row['Group'] = key
    row['Count'] = ys.shape[0]
    row['Minimum'] = ys.min()
    row['25th Percentile'] = np.percentile(ys, 25)
    row['Median'] = np.percentile(ys, 50)
    row['Mean'] = ys.mean()
    row['75th Percentile'] = np.percentile(ys, 75)
    row['90th Percentile'] = np.percentile(ys, 90)
    row['95th Percentile'] = np.percentile(ys, 95)
    row['99th Percentile'] = np.percentile(ys, 99)
    row['Maximum'] = ys.max()
    row['Standard Deviation'] = ys.std()
    median = np.median(ys)
    row['Median Absolute Deviation'] = np.median(
        [np.abs(y - median) for y in ys])
    q1 = np.percentile(ys, 25)
    q3 = np.percentile(ys, 75)
    iqr = q3 - q1
    l = q1 - 1.5 * iqr
    u = q3 + 1.5 * iqr
    outliers = [y for y in ys if not (l <= y <= u)]
    row['Tukey Outlier Count'] = len(outliers)

    df = df.append(row, ignore_index=True)
  print('Results for {}:'.format(thread_name))
  print('Units: Microseconds')
  print(df.to_string(index=False, float_format='%.2f', justify='center'))

  # https://en.wikipedia.org/wiki/Mann%E2%80%93Whitney_U_test
  u_statistic, p_value = sp.stats.mannwhitneyu(
      yss[0], yss[1], alternative='two-sided')
  cutoff = 0.05
  report_result = 'DIFFERED' if p_value < cutoff else 'DID NOT DIFFER'
  print('Mann–Whitney U test:')
  print(
      'The distributions of the two groups {} significantly (Mann-Whitney U={:.2f}, P={:.2f}, cutoff={:.2f}).'
      .format(report_result, u_statistic, p_value, cutoff))

  if args.graph == 'density':
    plt.title('{}: Before/After {} Durations'.format(thread_name,
                                                     target_event_name))
    plt.xlabel('Microseconds')
    plt.ylabel('Density')
    before_patch = matplotlib.patches.Patch(color='blue', label='Before')
    after_patch = matplotlib.patches.Patch(color='orange', label='After')
    plt.legend(handles=[before_patch, after_patch])
    plt.show()

  print('')
  print('===')
  print('')
