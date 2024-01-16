# Introduction
This document outlines the steps to pull changes from an upstream repository into a separate branch for testing and then merge those changes into the main branch after testing and resolving conflicts.

## High-level workflow for Merging Upstream Changes:

1. **Creating a New Branch:** When there are upstream changes you want to merge, create a new branch in the forked repository.

2. **Pulling Upstream Changes:** Pull the changes from the upstream repository into this new branch. Resolve any conflicts here.

3. **Testing:** Use this branch to test the deployment in Azure. Ensure everything works as expected.

4. **Creating a Pull Request:** Once you're confident with the changes, create a pull request to merge this branch into your main branch.

5. **Review and Merge:** Review the pull request. After approval, merge the pull request.

6. **Delete the Branch:** After the merge, you can safely delete the branch.

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

> Linear history is being retained so you will need to use **Rebase and Merge** or **Squash and Merge**.

### When to use Rebase
Use this when you want to maintain a detailed commit history from the feature/test branch in the main branch. It's suitable for code changes where each commit's history is important for context, such as new features or significant code revisions.

### When to use Squash
Opt for this when dealing with a series of minor or incremental changes, such as documentation updates or small tweaks. It combines all feature branch commits into a single commit for a cleaner main branch history, making it ideal for simpler or less impactful changes.

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
