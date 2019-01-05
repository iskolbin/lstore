[![Build Status](https://travis-ci.org/iskolbin/lstore.svg?branch=master)](https://travis-ci.org/iskolbin/lstore)
[![license](https://img.shields.io/badge/license-public%20domain-blue.svg)](http://unlicense.org/)
[![MIT Licence](https://badges.frapsoft.com/os/mit/mit.svg?v=103)](https://opensource.org/licenses/mit-license.php)


Lua partially persistent table
==============================

Library for undo/redo table operations. Currently works without history limiting. 


store.init( tbl, limit=math.huge )
----------------------------------

store.set( tbl, ...keys, value )
--------------------------------

store.unset( tbl, ...keys )
---------------------------

store.update( tbl, ...keys, (v, k, obj) -> w )
----------------------------------------------

store.insert( tbl, ...keys, index, value )
------------------------------------------

store.remove( tbl, ...keys, index )
-----------------------------------

store.push( tbl, ...keys, value )
---------------------------------

store.pop( tbl, ...keys )
-------------------------

store.unshift( tbl, ...keys, value )
------------------------------------

store.shift( tbl, ...keys )
---------------------------

store.undo( tbl )
-----------------

store.redo( tbl )
-----------------

store.setlimit( tbl, limit )
----------------------------

store.getlimit( tbl )
---------------------

store.__gethistory( tbl )
-------------------------

store.__sethistory( tbl )
-------------------------
