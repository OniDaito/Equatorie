###
                       __  .__              ________ 
   ______ ____   _____/  |_|__| ____   ____/   __   \
  /  ___// __ \_/ ___\   __\  |/  _ \ /    \____    /
  \___ \\  ___/\  \___|  | |  (  <_> )   |  \ /    / 
 /____  >\___  >\___  >__| |__|\____/|___|  //____/  .co.uk
      \/     \/     \/                    \/         
                                              CoffeeGL
                                              Benjamin Blundell - ben@section9.co.uk
                                              http://www.section9.co.uk

This software is released under Creative Commons Attribution Non-Commercial Share Alike
http://creativecommons.org/licenses/by-nc-sa/3.0/

###

class EquatorieSystem

  constructor : () ->
    @planet_data = {}

    # Data for the Equatorie mathematical model

    @planet_data.mars =
      equant : 2.0
      deferent : 1.0 
      angle : 30.0

    @mean_motus = 0     # Arc of motion of epicycle around deferent
    @mean_argument = 0  # Arc of motion of planet around epicycle


  calculateEpicycle : (planet) ->
    # relative to 0 degrees - the sign of aries    
    # Line of apsides
    x = @planet_data[planet].deferent * Math.sin(CoffeeGL.degToRad @planet_data[planet].angle)
    y = @planet_data[planet].deferent * Math.cos(CoffeeGL.degToRad @planet_data[planet].angle)
    
    # now rotate by mean motus and radius of epicycle (6.353 at present)

    rx = 6.353 * Math.sin( CoffeeGL.degToRad @mean_motus)
    ry = 6.353 * Math.cos( CoffeeGL.degToRad @mean_motus)

    [x + rx, y + ry]  


# Use Bullet physics and cylinders to represent the string
class EquatorieString extends CoffeeGL.Node
  constructor : (length, thickness, segments, world) ->
    super()
    seglength = length / segments

    segment_geom = new CoffeeGL.Shapes.Cylinder(thickness, 12, seglength)

    for i in [0..segments-1]
      colShape = new Ammo.btCylinderShape new Ammo.btVector3 thickness/2, seglength, thickness/2
      mass = 1.0
      localInertia = new Ammo.btVector3(0, 0, 0)
      colShape.calculateLocalInertia(mass, localInertia)
  
      base = 5.0 # raise up from 0
      motionState = new Ammo.btDefaultMotionState(new Ammo.btTransform( new Ammo.btQuaternion(0,0,0,1), new Ammo.btVector3(0, base + seglength * i,0)))
      rbInfo = new Ammo.btRigidBodyConstructionInfo(mass, motionState, colShape, localInertia)
      body = new Ammo.btRigidBody(rbInfo)

      segment_node = new CoffeeGL.Node(segment_geom)
      segment_node.phys = body
      @add segment_node

      world.addRigidBody(body)

    # add Constraints to make this look like string
    for i in [0..segments-2]
      pp = new Ammo.btVector3(0, seglength / 2,0)
      pq = new Ammo.btVector3(0, - seglength / 2,0)
      c = new Ammo.btPoint2PointConstraint(@children[i].phys, @children[i+1].phys, pp, pq )
      world.addConstraint(c,true)

  update : () ->
    trans = new Ammo.btTransform()
    for segment in @children
      segment.matrix.identity()

      tq = new CoffeeGL.Quaternion()

      segment.phys.getMotionState().getWorldTransform(trans)

      tv = new CoffeeGL.Vec3(trans.getRotation().getAxis().x(),
        trans.getRotation().getAxis().y() 
        trans.getRotation().getAxis().z())
      
      tq.fromAxisAngle(tv,trans.getRotation().getAngle())

      tmatrix = tq.getMatrix4()
      tmatrix.setPos new CoffeeGL.Vec3 trans.getOrigin().getX(), trans.getOrigin().getY(), trans.getOrigin().getZ()

      segment.matrix.copyFrom(tmatrix)


class Equatorie

  init : () =>
    
    @top_node = new CoffeeGL.Node()

    @system = new EquatorieSystem()

    r0 = new CoffeeGL.Request ('../shaders/basic.glsl')
    r0.get (data) =>
      @shader_basic = new CoffeeGL.Shader(data, {"uColour" : "uColour"})
      @white_string.shader = @shader_basic
      @white_string.uColour = new CoffeeGL.Colour.RGBA(0.0,1.0,1.0,1.0)

      r1 = new CoffeeGL.Request ('../shaders/basic_lighting.glsl')
      
      r1.get (data) =>
        @shader = new CoffeeGL.Shader(data, {"uAmbientLightingColor" : "uAmbientLightingColor"})
      
        r2 = new CoffeeGL.Request('../models/equatorie.js')

        r2.get (data) =>
          @g = new CoffeeGL.JSONModel(data) 
          @top_node.add(@g)

          # Should be three children nodes with this model. Attach the shaders
          
          @pointer  = @g.children[0]
          @epicycle = @g.children[1]
          @base     = @g.children[2]

          @pointer.shader   = @shader_basic
          @epicycle.shader  = @shader_basic
          @base.shader      = @shader

          @base.uAmbientLightingColor = new CoffeeGL.Colour.RGBA(0.0,1.0,1.0,1.0)

          @pointer.uColour = new CoffeeGL.Colour.RGBA(1.0,1.0,0.0,1.0)
          @epicycle.uColour = new CoffeeGL.Colour.RGBA(0.6,0.6,0.0,1.0)

          # Remove the pointer and add it as a child of the Epicycle
          @g.remove @pointer
          @epicycle.add @pointer

          # Rotate the Base so the Sign of Aries is in the right place
          q = new CoffeeGL.Quaternion()
          q.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(-90.0))

          @base.matrix.mult q.getMatrix4() 

     


    @c = new CoffeeGL.Camera.MousePerspCamera(new CoffeeGL.Vec3(0,0,25))
    @top_node.add(@c)

    @light = new CoffeeGL.Light.PointLight(new CoffeeGL.Vec3(0.0,5.0,25.0), new CoffeeGL.Colour.RGB(1.0,1.0,1.0) );

    @light2 = new CoffeeGL.Light.PointLight(new CoffeeGL.Vec3(0.0,15.0,5.0), new CoffeeGL.Colour.RGB(1.0,1.0,1.0) );

    @top_node.add(@light)
    @top_node.add(@light2)

    GL.enable(GL.CULL_FACE)
    GL.cullFace(GL.BACK)
    GL.enable(GL.DEPTH_TEST)


    # DAT Gui stuff
    # https://gist.github.com/ikekou/5589109
    g=new dat.GUI()
    g.remember(@)
    
    controller = g.add(@system,'mean_argument',0,360)
    controller = g.add(@system,'mean_motus',0,360)

    # Ammo.js setup for the string
    collisionConfiguration = new Ammo.btDefaultCollisionConfiguration()
    dispatcher = new Ammo.btCollisionDispatcher(collisionConfiguration)
    overlappingPairCache = new Ammo.btDbvtBroadphase()
    solver = new Ammo.btSequentialImpulseConstraintSolver()
    @dynamicsWorld = new Ammo.btDiscreteDynamicsWorld(dispatcher, overlappingPairCache, solver, collisionConfiguration)
    @dynamicsWorld.setGravity(new Ammo.btVector3(0, -10, 0))


    # Equatorie Base for Ammo.js

    baseShape = new Ammo.btCylinderShape new Ammo.btVector3 6.0, 0.1, 6.0
    baseTransform = new Ammo.btTransform()
    baseTransform.setIdentity()
    baseTransform.setOrigin new Ammo.btVector3 0, 0, 0

    baseMotionState = new Ammo.btDefaultMotionState(baseTransform)
    baseRigidBodyCI = new Ammo.btRigidBodyConstructionInfo(0,baseMotionState,baseShape, new Ammo.btVector3(0,0,0))
    @baseRigidBody = new Ammo.btRigidBody(baseRigidBodyCI)
    @dynamicsWorld.addRigidBody(@baseRigidBody)


    # Add String
    @white_string = new EquatorieString 8.0, 0.15, 20, @dynamicsWorld
    @top_node.add @white_string

    # Register for click events
    CoffeeGL.Context.mouseDown.add @onMouseDown, @


  update : (dt) =>
  
    @angle = dt * 0.001 * CoffeeGL.degToRad(20.0)
    if @angle >= CoffeeGL.PI * 2
      @angle = 0
    m = new CoffeeGL.Quaternion()
    m.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), @angle)
    m.transVec3(@light.pos)

    # Calculate the epicycle
    [x,y] = @system.calculateEpicycle("mars")

    @epicycle?.matrix.identity()
    @epicycle?.matrix.translate new CoffeeGL.Vec3 x,0,y


    @pointer?.matrix.identity()
    q = new CoffeeGL.Quaternion()
    q.fromAxisAngle(new CoffeeGL.Vec3(0,1,0), CoffeeGL.degToRad(@system.mean_argument))

    @pointer?.matrix.mult q.getMatrix4()

    @white_string.update()

    @dynamicsWorld.stepSimulation(dt / 1000.0, 10)
   
    @

  onMouseDown : (event) ->


  draw : () =>

    GL.clearColor(0.15, 0.15, 0.15, 1.0)
    GL.clear(GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT)

    @c.update()

    @top_node.draw() if @top_node?
  
eq = new Equatorie()

cgl = new CoffeeGL.App('webgl-canvas', eq, eq.init, eq.draw, eq.update)