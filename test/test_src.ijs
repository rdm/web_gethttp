NB. Use for projects with no Build target. 
NB. i.e. the "target" script to load is a source script
NB. The "target" script should have the same name as the project.
NB. Loads "target" script, then 
NB. loads test_{addonname}.ijs located in the same folder as this script.
targetname=. (#@getpath_j_ }. ]) 's' ,~ }: PROJECTFILE_jproject_
load PROJECTPATH_jproject_,targetname
TestPath=. getpath_j_ TESTFILE_jproject_
TestFile=.'test_', targetname
cocurrent 'base'
load TestPath,TestFile