module dau.ecs.entity;

class Entity {
  private {
    Component[TypeInfo] _components;
    bool _active;
  }

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
   *  T = Type of component to attach. Must be a subclass of Component.
   *  comp = component to attach
   */
  void attach(Component comp) {
    auto type = comp.baseComponentType;
    assert(comp._owner is null, "attaching component that already has an owner");
    assert(_components[type] is null, "cannot attach two of same component type");
    _components[type] = comp;
    comp._owner = this;
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

abstract class Component {
  private {
    bool _active;
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
    _owner._components[baseComponentType(this)] = null;
  }
}

private:
// helpers to get the 'base' component type, defined as the direct subclass of Component

// compile time component base type
template BaseComponentType(T : Component) {
  typeid(baseComponentType(T.init));
}

// runtime component base type
TypeInfo baseComponentType(Component c) {
  auto type = c.classinfo;
  assert(type != typeid(Component),  "Component type must be a subclass of Component");
  while(type.base != typeid(Component)) {
    type = type.base;
  }

  return type; 
}

version(unittest) {
  import std.exception : assertThrown;

  class A : Component { }
  class B : Component { }
  class C : A { }
  class D : B { }
  class E : D { }
}

// baseComponentType
unittest {
  assert(baseComponentType(A.init) == typeid(Component));
  assert(baseComponentType(B.init) == typeid(Component));
  assert(baseComponentType(C.init) == typeid(A));
  assert(baseComponentType(D.init) == typeid(B));
  assert(baseComponentType(E.init) == typeid(B));
}

// BaseComponentType
unittest {
  static assert(BaseComponentType!A == typeid(Component));
  static assert(BaseComponentType!B == typeid(Component));
  static assert(BaseComponentType!C == typeid(A));
  static assert(BaseComponentType!D == typeid(B));
  static assert(BaseComponentType!E == typeid(B));
}
