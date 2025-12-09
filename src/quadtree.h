// Copyright 2023 The Forgotten Server Authors. All rights reserved.
// Use of this source code is governed by the GPL-2.0 License that can be found in the LICENSE file.

#ifndef FS_QUADTREE_H
#define FS_QUADTREE_H

#include "otpch.h"

#include "creature.h"
#include "tile.h"

#include <generator>

class Creature;
class Tile;

namespace tfs::map::quadtree {

/// @brief Finds creatures within the specified range.
std::generator<std::weak_ptr<Creature>> find_creature_in_range(uint16_t start_x, uint16_t start_y, uint16_t end_x,
                                                                 uint16_t end_y);

/// @brief Finds the tile at the specified coordinates and layer.
std::shared_ptr<Tile> find_tile(uint16_t x, uint16_t y, uint8_t z);

/// @brief Creates a tile at the specified coordinates and layer.
void create_tile(uint16_t x, uint16_t y, uint8_t z, const std::shared_ptr<Tile>& tile);

/// @brief Moves a creature from one location to another within the quadtree.
void move_creature(uint16_t old_x, uint16_t old_y, uint16_t x, uint16_t y, const std::shared_ptr<Creature>& creature);

/// @brief Adds a creature into the quadtree at the specified coordinates.
void add_creature(uint16_t x, uint16_t y, const std::shared_ptr<Creature>& creature);

/// @brief Removes a creature from the quadtree at the specified coordinates.
void remove_creature(uint16_t x, uint16_t y, const std::shared_ptr<Creature>& creature);

} // namespace tfs::map::quadtree

/**
 * @brief Base class representing a Node.
 *
 * This class defines the interface for a node.
 * The class is non-copyable to prevent accidental copying of nodes.
 */
class Node
{
public:
	/// @brief Default constructor for Node.
	constexpr Node() = default;

	/**
	 * @brief Virtual destructor for Node.
	 *
	 * The virtual destructor allows for proper cleanup
	 * of derived classes
	 * that may be allocated dynamically.
	 */
	virtual ~Node() = default;

	/// Deleted copy constructor to ensure Node is non-copyable.
	Node(const Node&) = delete;
	/// Deleted assignment operator to ensure Node is non-copyable.
	Node& operator=(const Node&) = delete;

	/**
	 * @brief Check if the node is a leaf.
	 * @return true if the node is a leaf, false otherwise.
	 */
	virtual bool is_leaf() const = 0;

	/**
	 * @brief Set a child node at a specified index.
	 *
	 * This method assigns a child node to the
	 * current node at the given
	 * index. The index must be within valid bounds for child nodes (0 to 3).
	 * @param {index} The index at which to set the child node.
	 * @param {node} A pointer to the child node to be
	 * set.
	 */
	virtual void set_child(uint8_t index, Node* node) = 0;

	/**
	 * @brief Get a child node at a specified index.
	 * @param {index} The index of the child node to
	 * retrieve (0 to 3).
	 * @return A pointer to the child node, or nullptr if no child exists.
	 */
	virtual Node* get_child(uint8_t index) const = 0;
};

/// The number of bits used to represent the dimensions of a tile grid.
inline constexpr int32_t TILE_GRID_BITS = 3;
/// The size of the tile grid, calculated as 2 ^ TILE_GRID_BITS.
/// This value indicates the number of tiles that can fit along one dimension of the grid.
inline constexpr int32_t TILE_GRID_SIZE = (1 << TILE_GRID_BITS);
/// A mask to isolate the tile index within the bounds of the grid size.
/// This mask is used to ensure tile indices remain valid and wrap around correctly.
inline constexpr int32_t TILE_INDEX_MASK = (TILE_GRID_SIZE - 1);

/**
 * @class Branch
 * @brief Represents an internal (non-leaf) node in a Node.
 *
 * This class extends the Node interface and implements
 * the behavior of a branch node, which can have up to four children.
 */
class Branch final : public Node
{
public:
	/// @brief Default constructor for Branch.
	constexpr Branch() = default;
	~Branch();

	/// Deleted copy constructor to ensure Branch is non-copyable.
	Branch(const Branch&) = delete;
	/// Deleted assignment operator to ensure Branch is non-copyable.
	Branch& operator=(const Branch&) = delete;

	/**
	 * @brief Check if the node is a leaf node.
	 *
	 * This implementation always returns false,
	 * since Branch nodes always have the potential for children.
	 * @return false, indicating this is not a leaf.
	 */
	bool is_leaf() const override { return false; }

	/**
	 * @brief Set a child node at a specified index.
	 *
	 * @param index Index at which to set the child node (0–3).
	 * @param node Pointer to the child node.
	 */
	void set_child(uint8_t index, Node* node) override { nodes[index] = node; }

	/**
	 * @brief Get a child node at a specified index.
	 *
	 * @param index Index of the child node (0–3).
	 * @return Pointer to the child node, or nullptr if none exists.
	 */
	Node* get_child(uint8_t index) const override { return nodes[index]; }

private:
	/// Array storing pointers to the 4 child nodes.
	std::array<Node*, 4> nodes = {};
};

/**
 * @class Leaf
 * @brief Represents a leaf node in a Node.
 *
 * This class extends the Node interface and
 * is designed to hold data specific to a leaf node, such as creatures and tile information.
 */
class Leaf final : public Node
{
public:
	/**
	 * @brief Constructor for Leaf.
	 *
	 * This constructor initializes the leaf node with the specified
	 * coordinates.
	 */
	explicit Leaf() = default;
	~Leaf() = default;

	/// Deleted copy constructor to ensure Leaf is non-copyable.
	Leaf(const Leaf&) = delete;
	/// Deleted assignment operator to ensure Leaf is non-copyable.
	Leaf& operator=(const Leaf&) = delete;

	/**
	 * @brief Check if the node is a leaf node.
	 *
	 * This implementation always returns true,
	 * indicating that this object is a leaf.
	 * @return true, indicating that the node is a Leaf.
	 */
	bool is_leaf() const override { return true; }

	/**
	 * @brief Set a child node at a specified index.
	 *
	 * This method does nothing, as leaf nodes
	 * cannot have children.
	 * @param {index} The index at which to set the child node (not used).
	 * @param
	 * {node} A pointer to the child node to be set (not used).
	 */
	void set_child(uint8_t, Node*) override {}

	/**
	 * @brief Get a child node at a specified index.
	 *
	 * This method always returns nullptr, as leaf
	 * nodes do not have children.
	 * @param {index} The index of the child node to retrieve (not used).
	 * @return Always returns nullptr.
	 */
	Node* get_child(uint8_t) const override { return nullptr; };

	/**
	 * @brief Add a creature to the leaf.
	 *
	 * This method adds the specified creature to the Leaf
	 * node.
	 * @param {creature} A pointer to the creature to be added.
	 */
	void add_creature(const std::shared_ptr<Creature>& creature);

	/**
	 * @brief Remove a creature from the leaf.
	 *
	 * This method removes the specified creature from
	 * the leaf node.
	 * @param {creature} A pointer to the creature to be removed.
	 */
	void remove_creature(const std::shared_ptr<Creature>& creature);

	/**
	 * @brief A 3D array of pointers to tiles for the leaf across multiple layers.
	 *
	 *  This array holds pointers to `Tile` objects, organized in a three-dimensional
	 *  structure. The first dimension represents different layers, while the second
	 *  and third dimensions represent the x and y coordinates of the tiles within
	 *  each layer. Each layer can contain a grid of tiles.
	 */
	std::array<std::array<std::array<std::shared_ptr<Tile>, TILE_GRID_SIZE>, TILE_GRID_SIZE>, MAP_MAX_LAYERS> layers =
	    {};

	/// @brief A set of creatures (monsters, NPCs and players) present in this leaf node.
	boost::container::flat_set<std::weak_ptr<Creature>, std::owner_less<std::weak_ptr<Creature>>> creatures;

	Leaf* south_leaf = nullptr;
	Leaf* east_leaf = nullptr;
};

#endif // FS_QUADTREE_H
