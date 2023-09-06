---
title: "Some remarks on data collection"
permalink: /nus-resources/experiments/
author_profile: false
redirect_from: 
  - /experiment.html

---

You want to collect data over the internet but do not need specialised data, like eye movement or ERP data. There are two relatively easy to use / free-to-use (for NUS staff/students) options on the market at the moment:

+ [PCIbex](https://farm.pcibex.net/) (Zehr & Schwarz)
+ [Qualtrics](https://nus.au1.qualtrics.com/Q/MessagesSection?ContextLibraryID=UR_1H8xwes4UtHK6Sp&LibraryID=UR_1H8xwes4UtHK6Sp) (NUS login needed)
+ Honourable mentions: Gorilla (but requires payment), Pavlovia/PsychoPy (but requires Python), Amazon Mechanical Turk (but data quality concerns), Wenjuanxing, ...


Deciding between PCIbex and Qualtrics
-------------------------------------
If your study...
+ has a simple design
+ does not require pseudo-randomisation
+ does not involve collecting response time data
+ requires conditional logic

... consider using Qualtrics. Otherwise, PCIbex is a better option.

Qualtrics
---------

Pros:

+ Prolific is set up to seamlessly ["transition"](https://researcher-help.prolific.co/hc/en-gb/articles/360009224113-Qualtrics-integration-guide) participants to Qualtrics and back -- good participant experience.
+ [Advanced Formatting](https://www.qualtrics.com/support/survey-platform/survey-module/survey-tools/import-and-export-surveys/) lets you generate long surveys with relatively intuitive syntax. You can customise the look and feel using HTML tags ([a PDF cheatsheet](https://web.njit.edu/~marvin/cs103/lectures/ch04-6.pdf)). 
    + Use an Excel file (or Google Sheets) to create all your items and lists. Organise your trials into lists (= "blocks" in Qualtrics terminology). You should manually randomise your items.
	+ Use Excel commands to add the relevant keywords needed for Advanced Format.
	+ Copy the output from Excel into a text file.
	+ Import the Excel file into Qualtrics.
	+ Use the Randomizer function so that each participant will be randomly assigned to a block (= a particular list).
+ You can host files on Qualtrics (e.g. sound clips) but you need to manually upload them, which can be tedious.

Cons:

+ Raw data can be hard to read/parse (lots of columns, column names displayed in multiple rows)
+ Hard to customise if you do not like their default formatting options
+ Lots of point and click
+ No pseudorandomisation options

PCIbex
------
Two ways to set up an experiment:
1. [Old-fashioned way involving lots of Javascript](https://ibex-workshop-slides.netlify.app/), based on Alex Drummond's Ibex.
1. [Newer way, involving some PCIbex syntax and CSV](https://doc.pcibex.net/advanced-tutorial/8_creating-trial-template.html). Main advantage is that you can upload your materials in multiple CSV files (e.g. one for target items and another for filler items and a third for practice items), in a human-readable format.

Pros:

+ More flexibility in what to display and what to record (but requires tinkering with Javascript and CSS and PCIbex's own syntax)
+ Response time data
+ Raw data much easier to parse
+ Pseudorandomisation
+ Data hosting (limited)

Cons: 

+ Learning curve
+ Data loss