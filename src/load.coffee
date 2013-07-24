
# Load the Resources we need for the simulation

_loadLighting = (obj, c) =>
  r = new CoffeeGL.Request ('../shaders/basic_lighting.glsl')
  r.get (data) =>
    obj.shader = new CoffeeGL.Shader(data, {"uAmbientLightingColor" : "uAmbientLightingColor"})
    c.test()

_loadModel = (obj, c) =>
  r = new CoffeeGL.Request('../models/equatorie.js')
  r.get (data) =>
    obj.g = new CoffeeGL.JSONModel(data)
    c.test()
   
_loadBasic = (obj, c) =>
  r = new CoffeeGL.Request ('../shaders/basic.glsl')
  r.get (data) =>
    obj.shader_basic = new CoffeeGL.Shader(data, {"uColour" : "uColour"})
    c.test()

_loadPicking = (obj, c) =>
  r = new CoffeeGL.Request('../shaders/picking.glsl')
  r.get (data) =>
    obj.shader_picker = new CoffeeGL.Shader(data, {"uPickingColour" : "uPickingColour"})
    c.test()


# Load all the things we need, firing off a final signal when we do
loadAssets = (obj, signal) ->

  counter = {}
  counter.count = 4
  counter.signal = signal

  counter.test = () ->
    @count--
    if @count <= 0
      @signal.dispatch()

  _loadLighting obj, counter
  _loadModel obj, counter
  _loadBasic obj, counter
  _loadPicking obj, counter
  @

module.exports = 
  loadAssets : loadAssets