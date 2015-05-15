/**
 * A system examines and modifies components in the world.
 */
module dau.ecs.system;

import dau.ecs.world;

interface System {
  void run(World world);
}
