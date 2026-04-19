---
name: milestoned-development
description: Create and execute a milestone-driven development plan.
allowed-tools: Bash, Read, WebFetch, Skill(superpowers:*)
disable-model-invocation: true
---

# Overview

The user has a specific project they want executed. The user will give you details about the project and then
it is your goal to do the following:

1. Use the superpowers:brainstorm skill to think deeply about what the user wants and how this might be implemented. Examine the code to understand the project and any dependencies it may have that may be relevant. Ask the user for clarifying details if necessary and if there are multiple ways the design could be implemented, guide the user through the choices.

2. Create a detailed plan that is broken out by milestones. The goal is that each milestone should be achievable by a sub-agent that is small enough in scope that the sub-agent should be able to successfully complete it. 

3. Use the write-generated-doc skill to write the plan and open it. At this point the user may decide to make changes to the final plan. Make changes as the user requests and update the plan to reflect the decisions.

4. Once the plan is complete, wait for the user to give you the go-ahead to proceed with the plan.

5. Start executing on the plan in sequence. Each milestone should be executed by a sub-agent that is given the plan as context. When the sub-agent finishes executing on the plan, verify its work. If there are inconsistencies with the milestone implementation, instruct the sub-agent to make the necessary changes to drive it to completion. The sub-agent should ensure that the lints are clean. After you have verified that the implementation is to spec, make sure that the lint is clean and the changes committed. Then you can move on to the next milestone, starting with a new sub-agent.

6. After the last milestone has been completed, do a final review of the work. Present to the user your evaluation of the work and if there are additional changes that should be made, present those to the user.

# Guidelines

- Ideally each milestone would be verifiable. This typically means that unit tests that verify the work pass. Sometimes there are milestones which are not verifiable due to the nature of the work, but we should try to avoid that if at all possible.
 
- If the project involves debugging an issue, the milestones should reflect that. For example, if there is an issue for which the cause is unclear, consider adding milestones that help making that more clear, either through adding unit tests, debug logging, and so on. 

- Bias to using the superpowers skill set to perform the brainstorming and planning work.

- **Important**: after each milestone is verified, commit the changes and ensure the working tree is clean.

# User Context

$ARGUMENTS

