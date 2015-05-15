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
  package this() { }

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
     *  T = Type of component to attach. Must be a subclass of Component.
     */
    @property T component(T : Component)() {
      auto type = BaseComponentType!T;
      return cast(T) _components[type];
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
      auto type = comp.baseComponentType;
      assert(comp._owner is null, "attaching component that already has an owner");
      assert(_components[type] is null, "cannot attach two of same component type");
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
