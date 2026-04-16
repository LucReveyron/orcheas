# Goal

> Describe the overall objective of this project in 1–3 paragraphs.
> Be concrete: what is the end result? What does "done" look like?

Goal : Improve use of claude code for project.
I want a script (bash) that define the steps of claude code functionnality:
For example : 
1) Call agent for planification (define resriction in term of folder access and writes access)
2) Clear current agent context
3) Call agent for test implementation
4) Clear context
5) Call agent to define block for the project (example functions list) + documented them in the vault
6) clear context
7) Call agent for the first function to implement
8) clear context
9) Call agent for next functionn --> Loop
10) Call agent to test the current implementation and write a report (logs + summary of test)
11) Call agent for finetune based on the report 

In addition to that I want some confort features like token use status (progression bar)