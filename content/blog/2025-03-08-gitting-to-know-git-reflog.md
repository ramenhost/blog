+++
title = "Gitting to know Git reflog"
description = "A deep dive into git reflog with examples"
taxonomies.tags = ["Git", "Programming"]
+++

We know that git tracks changes to files in working directory, allowing us to easily undo modifications or revert to previous states. But what happens when we accidentally delete an unpublished branch or perform hard reset to a wrong commit? That's when we need undo button for the git operation itself. Have you ever used git reset --hard and then scrambled to recover your changes by copying commands from Stackoverflow or ChatGPT? If so, you've likely encountered git reflog. Think of it as a micro version control (log) for your Git references. For straight forward reverting of file changes, read this blog post from GitHub, How to undo (almost) anything with Git. While the GitHub's post covers reflog in brief, it doesn't delve into reflog's full power. There are articles with reflog commands to recover but I did not see any that explained why or how it works. This post aims to explain the internals of git in the context of reflog with examples.
