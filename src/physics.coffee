
# Web Worker for the String Physics in this system

# http://www.html5rocks.com/en/tutorials/workers/basics/

importScripts '/js/ammo.small.js'

# Given some bullet physics represent the string


# TODO - Limits on how far the string can be stretched
@ping = 0
@string_height = 0.4

class PhysicsString
  constructor : (length, thickness, segments, start, end, world) ->

    seglength = length / segments

    @children = []
    @length  = length

    for i in [0..segments-1]
      colShape = new Ammo.btCylinderShape new Ammo.btVector3 thickness/2, seglength, thickness/2
      mass = 1.0
      localInertia = new Ammo.btVector3(0, 0, 0)
      colShape.calculateLocalInertia(mass, localInertia)
  
      base = 5.0 # raise up from 0
      motionState = new Ammo.btDefaultMotionState(new Ammo.btTransform( new Ammo.btQuaternion(0,0,0,1), new Ammo.btVector3(0, base + seglength * i,0)))
      rbInfo = new Ammo.btRigidBodyConstructionInfo(mass, motionState, colShape, localInertia)
      body = new Ammo.btRigidBody(rbInfo)
      body.setDamping(0.99,0.99)
      @children.push body

      body.setActivationState(4) # BUG - DISABLE_DEACTIVATION isnt defined in Ammo.js but 4 is the number to use

      #body.setActivationState( Ammo.DISABLE_DEACTIVATION )

      world.addRigidBody(body)

    # add Constraints to make this look like string
    
    for i in [0..segments-2]
      pp = new Ammo.btVector3(0, 0,0)
      pq = new Ammo.btVector3(0, - seglength,0)
      c = new Ammo.btPoint2PointConstraint(@children[i], @children[i+1], pp, pq )
      world.addConstraint(c,true)
    

    # Add the fixed bodies for start and end
    fixShape = new Ammo.btBoxShape new Ammo.btVector3 0.1, 0.1, 0.1
    startTransform = new Ammo.btTransform()
    startTransform.setIdentity()
    startTransform.setOrigin new Ammo.btVector3 start.x, start.y, start.z

    startMotionState = new Ammo.btDefaultMotionState(startTransform)
    startRigidBodyCI = new Ammo.btRigidBodyConstructionInfo(0,startMotionState,fixShape, new Ammo.btVector3(0,0,0))
    @start = new Ammo.btRigidBody(startRigidBodyCI)
    @start.setCollisionFlags ( @start.getCollisionFlags() | 2 )
    @start.setActivationState( Ammo.DISABLE_DEACTIVATION )

    pp = new Ammo.btVector3(0, seglength / 2,0)
    pq = new Ammo.btVector3(0, -0.1,0)
    c = new Ammo.btPoint2PointConstraint(@children[segments-1], @start, pp, pq )

    world.addConstraint(c,true)
    world.addRigidBody(@start)

    endTransform = new Ammo.btTransform()
    endTransform.setIdentity()
    endTransform.setOrigin new Ammo.btVector3 end.x, end.y, end.z

    endMotionState = new Ammo.btDefaultMotionState(endTransform)
    endRigidBodyCI = new Ammo.btRigidBodyConstructionInfo(0,endMotionState,fixShape, new Ammo.btVector3(0,0,0))
    @end = new Ammo.btRigidBody(endRigidBodyCI)
    @end.setCollisionFlags ( @end.getCollisionFlags() | 2 )
    @end.setActivationState( Ammo.DISABLE_DEACTIVATION )

    postMessage {cmd: "ping", data: @end.isKinematicObject() }

    pp = new Ammo.btVector3(0, seglength / 2,0)
    pq = new Ammo.btVector3(0, -0.1,0)
    c = new Ammo.btPoint2PointConstraint(@children[0], @end, pp, pq )

    world.addConstraint(c,true)
    world.addRigidBody(@end)

  
  update : () ->
    trans = new Ammo.btTransform()
    list = []
    for segment in @children
      
      obj = {}

      segment.getMotionState().getWorldTransform(trans)

      obj.rax = trans.getRotation().getAxis().x()
      obj.ray = trans.getRotation().getAxis().y() 
      obj.raz = trans.getRotation().getAxis().z()
      obj.ra = trans.getRotation().getAngle()

      obj.x = trans.getOrigin().getX()
      obj.y = trans.getOrigin().getY()
      obj.z = trans.getOrigin().getZ()
      
      list.push obj

    list


interval = null

@startUp = () ->
  collisionConfiguration = new Ammo.btDefaultCollisionConfiguration()
  dispatcher = new Ammo.btCollisionDispatcher(collisionConfiguration)
  overlappingPairCache = new Ammo.btDbvtBroadphase()
  solver = new Ammo.btSequentialImpulseConstraintSolver()

  @dynamicsWorld = new Ammo.btDiscreteDynamicsWorld(dispatcher, overlappingPairCache, solver, collisionConfiguration)
  @dynamicsWorld.setGravity(new Ammo.btVector3(0, -10, 0))

  baseShape = new Ammo.btCylinderShape new Ammo.btVector3 6.0, 0.1, 6.0
  baseTransform = new Ammo.btTransform()
  baseTransform.setIdentity()
  baseTransform.setOrigin new Ammo.btVector3 0, 0, 0

  baseMotionState = new Ammo.btDefaultMotionState(baseTransform)
  baseRigidBodyCI = new Ammo.btRigidBodyConstructionInfo(0,baseMotionState,baseShape, new Ammo.btVector3(0,0,0))
  baseRigidBody = new Ammo.btRigidBody(baseRigidBodyCI)
  @dynamicsWorld.addRigidBody(baseRigidBody)

  # Create the white string
  @white_string = new PhysicsString 10.0, 0.01, 20, {x: 2, y:0.2, z:2}, {x: -2, y:0.2, z:-2}, @dynamicsWorld

  # ... and the black one
  @black_string = new PhysicsString 10.0, 0.01, 20, {x: -2, y:0.2, z:2}, {x: -4, y:0.2, z:2}, @dynamicsWorld

  last = Date.now()
  
  mainLoop = () ->
    now = Date.now()
    simulate(now - last)
    last = now

  if (interval)
    clearInterval(interval)
  
  interval = setInterval(mainLoop, 1000/60)


@moveBody = (body, pos) ->

  trans = new Ammo.btTransform()
  ms = new Ammo.btDefaultMotionState()
  body.getMotionState(ms)
  ms.getWorldTransform(trans)
  trans.setOrigin new Ammo.btVector3(pos.x,pos.y,pos.z)
  

  body.setActivationState(4);


  ms.setWorldTransform(trans)
  body.setMotionState(ms)



  # Damping seems to kill things :S

  data =
    black :
      segments : []
    white :
      segments : []

  data.white.segments = @white_string.update()
  data.black.segments = @black_string.update()

  postMessage { cmd: 'physics', data: data}


@simulate = (dt) ->
  dt = dt || 1

  @dynamicsWorld.stepSimulation(dt, 2) 

  data =
    black :
      segments : []
    white :
      segments : []

  data.white.segments = @white_string.update()
  data.black.segments = @black_string.update()

  postMessage { cmd: 'physics', data: data}



# Message format {cmd: <cmd> , data: <data obj> }

@onmessage = (event) -> 

  switch event.data.cmd
    when "startup" then startUp()
    when "white_start_move" then moveBody white_string.start, event.data.data 
    when "white_end_move" then moveBody white_string.end, event.data.data    
    when "black_start_move" then moveBody black_string.start, event.data.data    
    when "black_end_move" then moveBody black_string.end, event.data.data    
    else postMessage event.data.cmd


 
