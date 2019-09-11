We welcome contributions. If you have not already set up Fuchsia, follow the instructions [here](https://fuchsia.googlesource.com/docs/+/master/getting_started.md)

Follow the Contribution Guidelines [here](https://fuchsia.googlesource.com/docs/+/master/CONTRIBUTING.md)
This repo has some additional formatting nuances:
1. Commit messages should be formatted according to the Commit Message Format section [here](https://github.com/angular/angular.js/blob/master/CONTRIBUTING.md)
    i.e.
    ```
    <type>(<scope>): <subject>
    <BLANK LINE>
    <body>
    <BLANK LINE>
    <footer>
    ```
    e.g.
    ```
    feat(video): add play controls

    adds play controls and relevant tests

    JIRA-ISSUE-123 #done
    ```
2. Run `make fmt` and `make presubmit` and resolve any errors prior to `jiri upload`ing. This formats, lints, and runs tests on the code.
