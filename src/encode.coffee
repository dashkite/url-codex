import * as Fn from "@dashkite/joy/function"
import { generic } from "@dashkite/joy/generic"
import * as Type from "@dashkite/joy/type"
import * as Obj from "@dashkite/joy/object"
import * as It from "@dashkite/joy/iterable"
import * as Parsers from "./parsers"

import {
  failure
  flatten
} from "./helpers"

import { traverse } from "./traverse"

required = (f) ->
  ( bindings, description ) ->
    if bindings[ description.variable ]?
      f bindings, description
    else 
      throw failure "missing variable", 
        variable: description.variable

optional = ( fallback, f ) ->
  ( bindings, description ) ->
    if bindings[ description.variable ]?
      f bindings, description
    else 
      fallback

validators =

  string: ( bindings, { variable } ) ->
    value = bindings[ variable ]
    if Type.isString value
      value
    else
      throw failure "expected string", { variable }

  array: ( bindings, { variable } ) ->
    value = bindings[ variable ]
    if Type.isArray value
      value
    else
      throw failure "expected array", { variable }

  object: ( bindings, { variable } ) ->
    value = bindings[ variable ]
    if Type.isObject value
      value
    else
      throw failure "expected object", { variable }

Object.assign validators,

  path:
    default: required validators.string
    "?": optional null, validators.string
    "*": optional [], validators.array
    "+": required validators.array

  domain:
    default: required validators.string
    "?": optional null, validators.string
    "*": optional [], validators.array
    "+": required validators.array

  query:
    default: required validators.string
    "?": optional null, validators.string
    "*": optional {}, validators.object
    "+": required validators.object

evaluate = Fn.curry ( bindings, description ) ->
  { type, modifier } = description
  modifier ?= "default"
  validators[ type ][ modifier ] bindings, description

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
        if Type.isObject value
          It.map ( ([ key, value ]) -> { key, value } ),
            Object.entries value
        else { key, value }
      flatten
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