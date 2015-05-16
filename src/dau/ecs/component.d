/**
 * A component is a data bag that is attached to an Entity and operated on by a System.
 */
module dau.ecs.component;

import dau.ecs.entity;

/**
 * A component is a data bag that is attached to an Entity and operated on by a System.
 */
abstract class Component {
  package {
    bool _active = true;
    Entity _owner;
  }

  @property {
    /// The entity that this component is attached to
    Entity owner() { return _owner; }

    /// Get the component of type T attached to the same entity as this component
    T sibling(T : Component)() { return _owner.component!T; }

    /// A component becomes active when it is attached to an entity.
    /// Calling deactivate on a component or its parent entity sets active to false.
    bool active() { return _active; }
  }

  void deactivate() {
    _active = false;
    _owner._components[typeid(this)] = null;
  }
}
