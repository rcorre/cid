/**
 * An entity is a collection of components.
 */
module dau.ecs.entity;

import dau.ecs.world;
import dau.ecs.component;

/**
 * An entity is a collection of components.
 */
class Entity {
  package {
    World _world;
    Component[TypeInfo] _components;
    bool _active = true;
  }

  // for now, can only be constructed from World
  package this(World world) { _world = world; }

  final {
    /**
     * Whether the entity is active.
     * Deactivated entites are queued for removal and should not be accessed or used.
     */
    @property bool active() { return _active; }

    /**
     * Get an attached component of type T, or null if there is no attached component of that type.
     *
     * Params:
     *  T = Type of component to get. Must be a subclass of Component.
     */
    @property T component(T : Component)() {
      static assert(!is(T == Component), "must specify a subclass of Component");
      return cast(T) _components[typeid(T)];
    }

    /**
     * Attach a component to this entity.
     *
     * Asserts if comp is already attached to an entity
     * Asserts if this entity already has a component of the given type
     *
     * Params:
     *  comp = component to attach
     */
    void attach(Component comp) {
      auto type = typeid(comp);
      assert(comp._owner is null, "attaching component that already has an owner");
      assert(type !in _components, "attaching duplicate component " ~ comp.toString);
      _components[type] = comp;
      comp._owner = this;
      _world.addComponent(comp);
    }

    /**
     * Remove this entity and all of its attached components from the world.
     */
    void deactivate() {
      _active = false;
      foreach(comp ; _components.values) {
        comp._active = false;
      }
      _components = null;
    }
  }
}
