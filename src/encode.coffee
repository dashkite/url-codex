import * as Fn from "@dashkite/joy/function"
import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"
import * as Obj from "@dashkite/joy/object"
import * as It from "@dashkite/joy/iterable"
import * as Parsers from "./parsers"

import {
  failure
  flatten
  hasNoModifier
  hasOptionalModifier
  hasWildcardModifier
  hasPlusModifier
} from "./helpers"

import { traverse } from "./traverse"

evaluate = generic name: "evaluate"

generic evaluate, Type.isObject, hasNoModifier,
  ( bindings, { variable, modifier }) ->
    if ( value = bindings[ variable ] )?
      if Type.isString value
        value
      else
        throw failure "expected string", { variable }
    else
      throw failure "missing variable", { variable }

generic evaluate, Type.isObject, hasOptionalModifier,
  ( bindings, { variable, modifier }) -> 
    if ( value = bindings[ variable ] )?
      if Type.isString value
        value
      else
        throw failure "expected string", { variable }
    else
      null    

generic evaluate, Type.isObject, hasWildcardModifier,
  ( bindings, { variable, modifier }) ->
    if ( value = bindings[ variable ] )?
      if Type.isArray value
        value
      else
        throw failure "expected array", { variable }
    else
      []
      
generic evaluate, Type.isObject, hasPlusModifier,
  ( bindings, { variable, modifier }) ->
    if ( value = bindings[ variable ] )?
      if Type.isArray value
        value
      else 
        throw failure "expected array", { variable }
    else
      throw failure "missing variable", { variable }

evaluate = Fn.curry Fn.binary evaluate

prefix = Fn.curry ( p, value ) -> 
  if value? && value != "" then p + value else value

suffix = Fn.curry ( s, value ) ->
  if value? && value != "" then value + s else value

encode = Fn.curry ( template, bindings ) ->
  result = ""
  append = (value) -> result += value
  traverse ( Parsers.template template ),
    expression: evaluate bindings
    protocol: Fn.pipe [
      suffix "://"
      append
    ]
    domain: Fn.pipe [
      It.join "."
      append
    ]
    path: Fn.pipe [
      It.map encodeURIComponent
      It.join "/"
      prefix "/"
      append
    ]
    query: Fn.pipe [
      It.select ({ key, value }) -> value?
      It.map ({ key, value }) ->
        if Type.isArray value
          { key, value: _value } for _value in value
        else { key, value }
      It.map ({ key, value }) -> "#{key}=#{encodeURIComponent value}"
      It.join "&"
      prefix "?"
      append
    ]
    missing:
      # if there's no origin, include leading /
      path: -> result = "/" if result == ""
          
  result

export { encode }