import scenarios from "./scenarios"

{ literals, variables } = scenarios

nextName = (name) ->
  switch name
    when "A" then "B"
    when "B" then "C"
    when "C" then "A"

generateBindings = ( name, modifier ) ->
  switch modifier
    when "?" then literals[ name ]
    when "+", "*" then [ literals[ name ], literals[ nextName name ] ]


export {
  literals
  variables
  nextName
  generateBindings
}