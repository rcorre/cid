/**
 * The world is the top level container for all ECS types.
 * It stores and provides access to Entity, Component, and System collections.
 */
module dau.ecs.world;

import std.range : take, takeNone;
import std.algorithm : find;
import dau.ecs.entity;
import dau.ecs.system;
import dau.ecs.component;
import dau.util.droplist;
import dau.util.helpers : selectRange;

/// Stores entities and components.
struct World {
  private {
    alias EntityList = DropList!(Entity, x => !x.active);
    alias ComponentList = DropList!(Component, x => !x.active);

    System[]                _systems;
    EntityList[string]      _entities;
    ComponentList[TypeInfo] _components;
  }

  package {
    void addComponent(Component comp) {
      auto type = comp.baseComponentType;
      auto list = type in _components;
      if (list is null) {
        _components[type] = new ComponentList();
      }

      list.insert(comp);
    }
  }

  @property {
    /**
     * Find all entities with a given tag.
     *
     * If you want to be able to search for an entity, assign it a tag on creation.
     * Null-tagged entities can only be located by iterating over components of a given type.
     *
     * Params:
     *  tag = tag to search for. must be non-null, null-tagged entites are not searchable.
     */
    auto findEntities(string tag) {
      int idx = (tag in _entities) ? 1 : 0;
      return selectRange(idx, takeNone!(typeof(_entities[tag][])), _entities[tag][]);
    }

    /**
     * Get all components of type T.
     */
    auto components(T)() {
      return _components[baseComponentType!T][];
    }

    /**
     * Get the system of type T. Throws if no such system.
     */
    auto system(T)() {
      auto sys = _systems.find!(x => typeid(x) == typeid(T));
      assert(!sys.empty, "could not find system of type " ~ T.stringof);
      return sys.front;
    }
  }

  /**
   * Add a new entity to the world and return a reference to it.
   *
   * Params:
   *  tag = optional tag that can be used to search for this entity.
   */
  Entity createEntity(string tag = null) {
    auto entity = new Entity();

    if (tag !in _entities) {
      _entities[tag] = new EntityList();
    }

    _entities[tag].insert(entity);

    return entity;
  }

  /// Add a new system to the world.
  void addSystem(System sys) {
    _systems ~= sys;
  }
}

version(unittest) {
  import std.algorithm : equal, canFind;
  import std.exception : assertThrown;

  class Position : Component {
    int x, y;
  }

  abstract class Drawable : Component {
    string color;
  }

  class Primitive : Drawable {
    string type;
  }

  class Sprite : Drawable {
    string name;
  }
}

/// find entities by tags
unittest {
  auto world = new World;

  auto anon = world.createEntity();
  auto map = world.createEntity("map");
  Entity[] tiles;
  foreach(i ; 0..5) {
    tiles ~= world.createEntity("tile");
  }

  auto mapList = world.findEntities("map");
  assert(!mapList.empty && mapList.front == map);

  auto anonList = world.findEntities(null);
  assert(!anonList.empty && anonList.front == anon);

  auto tileList = world.findEntities("tile");
  assert(!tileList.empty);
  foreach(t; tileList) {
    assert(tiles.canFind(t));
  }

  auto notFound = world.findEntities("nope");
  assert(notFound.empty);
}
