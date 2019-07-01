# Fakemon

Such a long asked for feature. It is possible but it isn't for the faint of hearth. It requires you to probably learn some new things, you will most likely encounter issues. When you do encounter the issues please let me know and I will try to help.


## Using Fakemon

The app gets the Fakemon data by downloading it from a zip file, the zip files requires to be setup in a certian way, please see the [fakemon-example](https://github.com/Jerakin/fakemon-example) for an example how of to structure the data.

## Two ways
There are two ways to setup this data, one is doing it in pure JSON. Which is probably easier if you only have a few Fakemon. The other way is to use the [FakemonConverter](https://github.com/Jerakin/FakemonConverter), this small python script/application that uses a downloaded Google Sheet (saved in the Microsoft Excel format) to automaticall format and output the data for you. This can be a lot easier if you have a lot of Fakemon you want to add.


### Step by Step
Create a github repository where your Fakemon will live. This is explained in [fakemon-example/USING_GIT.md](https://github.com/Jerakin/fakemon-example/blob/master/USING_GIT.md)

Install the requirements to use the [FakemonConverter](https://github.com/Jerakin/FakemonConverter#installation)

Create a copy of this [Google Sheet](https://docs.google.com/spreadsheets/d/1HExvO-GDpKK8RLf8z6qRS-dR5P0kkk8sHHT1JWjSfWY/edit#gid=0) and start inputting your data.

When you are done download it as per the instructions in  [FakemonConverter](https://github.com/Jerakin/FakemonConverter#usage)

Then start the FakemonConverter, input the `.xlsx` (Microsoft Excel) document and pick your output folder to be the same as the folder you created when making a git repository.

If you want images remember to add them to this folder too.
