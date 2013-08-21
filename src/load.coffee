
# Load the Resources we need for the simulation

# We should properly add this as a coffeegl class for loading things in a queue

_loadLighting = (obj, c) =>
  r = new CoffeeGL.Request ('../shaders/basic_lighting.glsl')
  r.get (data) =>
    obj.shader = new CoffeeGL.Shader(data, {"uAmbientLightingColor" : "uAmbientLightingColor"})
    c.test()

_loadAniso = (obj, c) =>
  r = new CoffeeGL.Request ('../shaders/anisotropic.glsl')
  r.get (data) =>
    obj.shader_aniso = new CoffeeGL.Shader(data, {
      "uAmbientLightingColor" : "uAmbientLightingColor",
      "uSpecColour" : "uSpecColour",
      "uSamplerNormal" : "uSamplerNormal",
      "uAlphaX" : "uAlphaX",
      "uAlphaY" : "uAlphaY"
    })
  
    c.test()

_loadModel = (obj, c) =>
  r = new CoffeeGL.Request('../models/equatorie.js')
  r.get (data) =>
    obj.equatorie_model = new CoffeeGL.JSONModel(data)
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

_loadEpicycleNormal = (obj, c) =>
  obj.epicycle_normal = new CoffeeGL.Texture("../models/epicycle_NRM.jpg",{unit : 1}, () => 
    c.test()
  )

_loadPlateNormal = (obj, c) =>
  obj.plate_normal = new CoffeeGL.Texture("../models/plate_NRM.jpg",{unit : 1}, () => 
    c.test()
  )

_loadRimNormal = (obj, c) =>
  obj.rim_normal = new CoffeeGL.Texture("../models/ring_NRM.jpg",{unit : 1}, () => 
    c.test()
  )

_loadPointerNormal = (obj, c) =>
  obj.pointer_normal = new CoffeeGL.Texture("../models/label_NRM.jpg",{unit : 1}, () => 
    c.test()
  )

_loadBaseNormal = (obj, c) =>
  obj.base_normal = new CoffeeGL.Texture("../models/base_texture_NRM.jpg",{unit : 1}, () => 
    c.test()
  )

_loadBackingShader = (obj,c) =>
  r = new CoffeeGL.Request('../shaders/background.glsl')
  r.get (data) =>
    obj.shader_background = new CoffeeGL.Shader(data)
    c.test()

# Load all the things we need, firing off a final signal when we do
loadAssets = (obj, signal, signal_progress) ->

  counter = {}


  counter.test = () ->
    @count--
    @signal_progress.dispatch( (11 - @count) / 11 )
    if @count <= 0
      @signal.dispatch()


  _loadLighting obj, counter
  _loadModel obj, counter
  _loadBasic obj, counter
  _loadPicking obj, counter
  _loadAniso obj, counter
  _loadEpicycleNormal obj, counter
  _loadPlateNormal obj, counter
  _loadRimNormal obj, counter
  _loadPointerNormal obj, counter
  _loadBaseNormal obj, counter
  _loadBackingShader obj, counter
  
  counter.count = 11
  counter.signal = signal
  counter.signal_progress = signal_progress

  @

module.exports = 
  loadAssets : loadAssets