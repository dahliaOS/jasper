Life of a CL
============


## Creating a change

1.  Start a new local branch
    ```
    git checkout -b foo
    ```

1.  Code away.

1.  Create a new commit. [git-gui](https://git-scm.com/docs/git-gui) (or
    [GitX](http://gitx.frim.nl/) for macOS) is a great for handling commits;
    install it with the following command:
    ```
    sudo apt-get install git-gui
    ```

1.  Upload the change to Gerrit
    ```
    git push origin HEAD:refs/for/master
    ```


## Updating a change

Just make code changes, update your commit, and git-push.


## Finalizing the change

Changes are submitted via the Gerrit web UI. Once the change is in:

1.  Delete your local branch
    ```
    git branch -D foo
    ```

1.  Update your master branch
    ```
    git checkout master
    git pull --rebase
    ```
