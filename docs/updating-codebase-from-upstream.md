# Introduction
This document outlines the steps to pull changes from an upstream repository into a separate branch for testing and then merge those changes into the main branch after testing and resolving conflicts.

## Prerequisites

- Ensure you have Git installed on your system.
- Have access to your GitHub repository and the upstream repository (Microsoft's repository in this case).

# Steps

## 1. Navigate the local repo.

## 2. Update the local main branch.

Ensure your local `main` branch is up to date with the remote repository,

`git checkout main`
`git pull origin main`

## 3. Fetch changies from upstream
Fetch changes from the upstream repository without merging them.

`git fetch upstream`

## 4. Create a new branch for testing

Create a new branch based on the `main` to test the upstream changes.
> This is important, as it protects the stability of the branch from which the code is deployed to Azure (main branch).

`git checkout -b test-upstream-changes main`

## 5. Merge upstream changes into the new branch.

Merge the changes from the upstream repository into your new branch.

` git merge upstream/main`

### Resolving merge conflicts

If you encounter merge conflicts, Git will pause the merge process and mark the files that have conflicts. Here is how to resolve them:

- Open the conflicted files in VS Code.
- Look for the areas marked as conflicts (usually indicated by `<<<<<<`, `======`, and `>>>>>>>`).
- Manually edit the files to resolve the conflicts. Choose which changes to keep or combine as needed.
- After resolving conflicts, add the files to staging:
    `git add .`
- Then, continue the merge process:
    `git merge --continue`
- Once all conflicts are resolved and the merge is successful, proceed with the next steps.

## 6. Push the new branch to Github

`git push origin test-upstream-changes`

## 7. Open a Pull Request in GitHub

- Go to the repository in GitHub.
- Open a pull request for the `test-upstream-changes` branch against the `main` branch.
- This initiates the review process.

> Do not merge it yet.

## 8. Deploy the Test branch

Deploy the `test-upstream-changes` branch to Azure to test the changes.

## 9. Review and merge the pull request

- If the tests are successful, merge the changes into main by merging the pull request into the `main` branch through the GitHub interface.

## 10. Update the local main branch and clean up

After merging the pull request, update the local `main` branch and delete the test branch.

`git checkout main`
`git pull origin main`
`git branch -d test-upstream-changes`
`git push origin --delete test-upstream-changes`

## 11. Redeploy from main

Re-deploy the codebase from the `main` branch.

# Conclusion

This process ensures that changes from the upstream repository are tested in isolation before being integrated into the main branch, minimising the risk of disruption to the main codebase.
