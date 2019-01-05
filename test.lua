local store = require('store')

local x = {}

store.init(x)
store.set( x, 'y', {z = 1} )
assert( x.y.z == 1 )
store.set( x, 'y', 'z', 2 )
assert( x.y.z == 2 )
store.set( x, 'y', 'z', 3 )
assert( x.y.z == 3 )
store.undo( x )
assert( x.y.z == 2 )
store.undo( x )
assert( x.y.z == 1 )
store.redo( x )
assert( x.y.z == 2 )

store.unset( x, 'y', 'z' )
assert( x.y.z == nil )
store.redo( x )
assert( x.y.z == nil )
store.undo( x )
assert( x.y.z == 2 )

store.set( x, 'y', {} )
assert( next(x.y) == nil )
store.push( x, 'y', 1 )
assert( x.y[1] == 1 )
store.push( x, 'y', 2 )
assert( x.y[1] == 1 and x.y[2] == 2 )
store.undo( x )
assert( x.y[1] == 1 )
store.redo( x )
assert( x.y[1] == 1 and x.y[2] == 2 )
store.push( x, 'y', 3 )
assert( x.y[1] == 1 and x.y[2] == 2 and x.y[3] == 3 )

store.insert( x, 'y', -1, 2.5 )
assert( x.y[1] == 1 and x.y[2] == 2 and x.y[3] == 2.5 and x.y[4] == 3 )
store.insert( x, 'y', 1, 0.5 )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 2 and x.y[4] == 2.5 and x.y[5] == 3 )
store.undo( x )
assert( x.y[1] == 1 and x.y[2] == 2 and x.y[3] == 2.5 and x.y[4] == 3 )
store.redo( x )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 2 and x.y[4] == 2.5 and x.y[5] == 3 )

store.pop( x, 'y' )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 2 and x.y[4] == 2.5 )
store.pop( x, 'y' )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 2 )
store.undo( x )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 2 and x.y[4] == 2.5 )
store.redo( x )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 2 )

store.shift( x, 'y' )
assert( x.y[1] == 1 and x.y[2] == 2 )
store.undo( x )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 2 )
store.redo( x )
assert( x.y[1] == 1 and x.y[2] == 2 )

store.unshift( x, 'y', 0.5 )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 2 )
store.undo( x )
assert( x.y[1] == 1 and x.y[2] == 2 )
store.redo( x )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 2 )

store.update( x, 'y', 3, function( v ) return v + 1 end )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 3 )
store.undo( x )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 2 )
store.redo( x )
assert( x.y[1] == 0.5 and x.y[2] == 1 and x.y[3] == 3 )
