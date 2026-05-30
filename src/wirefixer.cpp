#include "wirefixer.h"
#include <godot_cpp/core/class_db.hpp>

using namespace godot;

WireFixer::WireFixer() {
    total_wires = 4;
    connected_wires = 0;
    selected_left = -1;
}

void WireFixer::_bind_methods() {
    ClassDB::bind_method(D_METHOD("setup", "num_wires"), &WireFixer::setup);
    ClassDB::bind_method(D_METHOD("try_connect", "left_index", "right_index"), &WireFixer::try_connect);
    ClassDB::bind_method(D_METHOD("disconnect_wire", "left_index"), &WireFixer::disconnect_wire);
    ClassDB::bind_method(D_METHOD("is_complete"), &WireFixer::is_complete);
    ClassDB::bind_method(D_METHOD("get_selected_left"), &WireFixer::get_selected_left);
    ClassDB::bind_method(D_METHOD("set_selected_left", "index"), &WireFixer::set_selected_left);
    ClassDB::bind_method(D_METHOD("get_color", "index"), &WireFixer::get_color);
    ClassDB::bind_method(D_METHOD("get_right_order", "index"), &WireFixer::get_right_order);
    ClassDB::bind_method(D_METHOD("get_connection", "left_index"), &WireFixer::get_connection);

    ADD_SIGNAL(MethodInfo("wire_connected", PropertyInfo(Variant::INT, "left_index")));
    ADD_SIGNAL(MethodInfo("wire_wrong", PropertyInfo(Variant::INT, "left_index")));
    ADD_SIGNAL(MethodInfo("puzzle_complete"));
}

void WireFixer::setup(int num_wires) {
    total_wires = num_wires;
    connected_wires = 0;
    selected_left = -1;

    wire_colors.clear();
    wire_colors.push_back("red");
    wire_colors.push_back("blue");
    wire_colors.push_back("green");
    wire_colors.push_back("yellow");

    // shuffle right side
    right_order.clear();
    for (int i = 0; i < total_wires; i++) right_order.push_back(i);
    for (int i = total_wires - 1; i > 0; i--) {
        int j = rand() % (i + 1);
        int tmp = right_order[i];
        right_order[i] = right_order[j];
        right_order[j] = tmp;
    }

    connections.clear();
    for (int i = 0; i < total_wires; i++) connections.push_back(-1);
}

bool WireFixer::try_connect(int left_index, int right_index) {
    // right_index here is the position on the right column
    // check if the color at right position matches left
    if (right_order[right_index] == left_index) {
        connections[left_index] = right_index;
        connected_wires++;
        emit_signal("wire_connected", left_index);
        if (connected_wires >= total_wires) {
            emit_signal("puzzle_complete");
        }
        return true;
    } else {
        emit_signal("wire_wrong", left_index);
        return false;
    }
}

void WireFixer::disconnect_wire(int left_index) {
    if (connections[left_index] != -1) {
        connections[left_index] = -1;
        connected_wires--;
    }
}

bool WireFixer::is_complete() const {
    return connected_wires >= total_wires;
}

int WireFixer::get_selected_left() const { return selected_left; }
void WireFixer::set_selected_left(int index) { selected_left = index; }
String WireFixer::get_color(int index) const { return wire_colors[index]; }
int WireFixer::get_right_order(int index) const { return right_order[index]; }
int WireFixer::get_connection(int left_index) const { return connections[left_index]; }