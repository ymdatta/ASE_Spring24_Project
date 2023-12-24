-- vim: set et sts=2 sw=2 ts=2 
local smo=require"smo"
local l=require"smolib"
local the,COLS,DATA,NUM,SYM = smo.the,smo.COLS,smo.DATA,smo.NUM,smo.SYM

local eg={}

function eg.the() oo(the) end 

l.cli(the)
eg[the.todo]()

l.rogues()
