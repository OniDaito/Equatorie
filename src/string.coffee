# Use Bullet physics and cylinders to represent the string
class EquatorieString extends CoffeeGL.Node
  constructor : (length, thickness, segments, start, end, world) ->
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


    # Add the fixed bodies for start and end
    fixShape = new Ammo.btBoxShape new Ammo.btVector3 0.1, 0.1, 0.1
    startTransform = new Ammo.btTransform()
    startTransform.setIdentity()
    startTransform.setOrigin new Ammo.btVector3 start.x, start.y, start.z

    startMotionState = new Ammo.btDefaultMotionState(startTransform)
    startRigidBodyCI = new Ammo.btRigidBodyConstructionInfo(0,startMotionState,fixShape, new Ammo.btVector3(0,0,0))
    @start = new Ammo.btRigidBody(startRigidBodyCI)

    pp = new Ammo.btVector3(0, seglength / 2,0)
    pq = new Ammo.btVector3(0, -0.1,0)
    c = new Ammo.btPoint2PointConstraint(@children[segments-1].phys, @start, pp, pq )

    world.addConstraint(c,true)
    world.addRigidBody(@start)

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

module.exports = 
  EquatorieString : EquatorieString