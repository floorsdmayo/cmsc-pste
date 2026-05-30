#pragma once
#include <godot_cpp/classes/node.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/string.hpp>

namespace godot {

class WireFixer : public Node {
    GDCLASS(WireFixer, Node)

private:
    int total_wires;
    int connected_wires;
    int selected_left;  // -1 if none selected
    PackedStringArray wire_colors;
    PackedInt32Array right_order;  // shuffled indices
    PackedInt32Array connections;  // -1 = unconnected

public:
    static void _bind_methods();
    WireFixer();

    void setup(int num_wires);
    bool try_connect(int left_index, int right_index);
    void disconnect_wire(int left_index);
    bool is_complete() const;
    int get_selected_left() const;
    void set_selected_left(int index);
    String get_color(int index) const;
    int get_right_order(int index) const;
    int get_connection(int left_index) const;
};

}