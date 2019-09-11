# Copyright 2016 The Fuchsia Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

"""Recipe for building and running pre-submit checks for the modules repo."""

from recipe_engine.recipe_api import Property


DEPS = [
    'infra/goma',
    'infra/jiri',
    'recipe_engine/path',
    'recipe_engine/properties',
    'recipe_engine/raw_io',
    'recipe_engine/step',
]

PROPERTIES = {
    'category': Property(kind=str, help='Build category', default=None),
    'patch_gerrit_url': Property(kind=str, help='Gerrit host', default=None),
    'patch_project': Property(kind=str, help='Gerrit project', default=None),
    'patch_ref': Property(kind=str, help='Gerrit patch ref', default=None),
    'patch_storage': Property(kind=str, help='Patch location', default=None),
    'patch_repository_url': Property(kind=str, help='URL to a Git repository',
                                     default=None),
}

def run_jiri_update(api, manifest, remote):
    api.jiri.init()
    api.jiri.import_manifest(manifest, remote)
    api.jiri.update()
    step_result = api.jiri.snapshot(api.raw_io.output())
    snapshot = step_result.raw_io.output
    step_result.presentation.logs['jiri.snapshot'] = snapshot.splitlines()

def RunSteps(api, category, patch_gerrit_url, patch_project, patch_ref,
             patch_storage, patch_repository_url):
    api.goma.ensure_goma()
    api.jiri.ensure_jiri()

    # Checkout the 'userspace' manifest.
    run_jiri_update(api, 'userspace',
                    'https://fuchsia.googlesource.com/manifest')
    if patch_ref is not None:
        api.jiri.patch(patch_ref, host=patch_gerrit_url)

    # The make script defaults to a debug build unless specified otherwise. It
    # also always hardcodes x86-64 as the target architecture. Since this is
    # only exercising Dart code we don't parameterize the recipe for any other
    # architecture.
    with api.goma.build_with_goma():
        modules_repo_path = api.path['start_dir'].join('apps/modules')
        api.step('build and run presubmit tests', ['make', 'presubmit'],
                 cwd=modules_repo_path,
                 env={'GOMA': 1, 'MINIMAL': 1, 'NO_ENSURE_GOMA': 1,
                      'GOMA_DIR': api.goma.goma_dir,
                      'PUB_CACHE': api.path['cache'].join('pub')})

def GenTests(api):
    yield api.test('basic')
    yield api.test('cq') + api.properties.tryserver(
        gerrit_project='modules',
        patch_gerrit_url='fuchsia-review.googlesource.com',
    )
