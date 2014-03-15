# requirium

An autoload alternative for Ruby.

* https://github.com/SilverPhoenix99/requirium

## INSTALL:

    gem install requirium

## DESCRIPTION:

Requirium offers advanced loading mechanisms, similar to Ruby's autoload and require.

`autoload` calls Ruby's `load`, while `autorequire` calls Ruby's `require` as expected, so they both search for files as Ruby does. But they do more than that, such as loading multiple files for a single constant, and batching multiple constants with a single call.

To use, simply extend the Requirium module and the loading methods will be available:

```ruby
module M
  extend Requirium

  autoload :A # loads 'a' (camel case constant to snake case file name)
  autoload :B, 'b', 'b1', 'dir/b2' # loads the 3 files
  autoload A: nil, B: ['b', 'b1', 'dir/b2'] # joins the 2 previous options in a single call

  autorequire :A # requires 'a'
  autorequire :B, 'b', 'b1', 'dir/b2' # requires the 3 files
  autorequire A: nil, B: ['b', 'b1', 'dir/b2'] # joins the 2 previous options in a single call
  
  # theses next examples are similar to the previous ones,
  # but they load relative to the current file
  
  autoload_relative :X
  autoload_relative :Y, 'y', 'y1', 'dir/y2'
  autoload_relative X: nil, Y: ['y', 'y1', 'dir/y2']
  
  autorequire_relative :X
  autorequire_relative :Y, 'y', 'y1', 'dir/y2'
  autorequire_relative X: nil, Y: ['y', 'y1', 'dir/y2']
end
```

## LICENSE:

(The MIT License)

Copyright &copy; 2014 Pedro Pinto

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
'Software'), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.