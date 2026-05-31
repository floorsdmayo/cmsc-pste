#include "snake_game.h"
#include <godot_cpp/core/class_db.hpp>
#include <cstdlib>
#include <ctime>
#include <godot_cpp/variant/utility_functions.hpp>

using namespace godot;

SnakeLogic::SnakeLogic() {
    grid_width = 20;
    grid_height = 20;
    score = 0;
    phase = 0;
    game_over = false;
    won = false;
    ate_last_step = false;
    direction = Vector2i(1, 0);
    next_direction = Vector2i(1, 0);
    apples_since_last_wall = 0;
    light_radius = 4.0f;
    base_light_radius = 4.0f;
    max_light_radius = 8.0f;
    move_speed = 0.15f;
    srand(time(nullptr));
}

void SnakeLogic::_bind_methods() {
    ClassDB::bind_method(D_METHOD("setup", "width", "height"), &SnakeLogic::setup);
    ClassDB::bind_method(D_METHOD("set_direction", "dx", "dy"), &SnakeLogic::set_direction);
    ClassDB::bind_method(D_METHOD("step"), &SnakeLogic::step);
    ClassDB::bind_method(D_METHOD("clear_walls"), &SnakeLogic::clear_walls);
    ClassDB::bind_method(D_METHOD("clear_statues"), &SnakeLogic::clear_statues);
    ClassDB::bind_method(D_METHOD("trim_to", "length"), &SnakeLogic::trim_to);
    ClassDB::bind_method(D_METHOD("get_score"), &SnakeLogic::get_score);
    ClassDB::bind_method(D_METHOD("get_phase"), &SnakeLogic::get_phase);
    ClassDB::bind_method(D_METHOD("is_game_over"), &SnakeLogic::is_game_over);
    ClassDB::bind_method(D_METHOD("is_won"), &SnakeLogic::is_won);
    ClassDB::bind_method(D_METHOD("get_snake_body"), &SnakeLogic::get_snake_body);
    ClassDB::bind_method(D_METHOD("get_apple_pos"), &SnakeLogic::get_apple_pos);
    ClassDB::bind_method(D_METHOD("get_walls"), &SnakeLogic::get_walls);
    ClassDB::bind_method(D_METHOD("get_statues"), &SnakeLogic::get_statues);
    ClassDB::bind_method(D_METHOD("get_move_speed"), &SnakeLogic::get_move_speed);
    ClassDB::bind_method(D_METHOD("get_light_radius"), &SnakeLogic::get_light_radius);
    ClassDB::bind_method(D_METHOD("reset_for_pong"), &SnakeLogic::reset_for_pong);

    ADD_SIGNAL(MethodInfo("apple_eaten", PropertyInfo(Variant::INT, "score")));
    ADD_SIGNAL(MethodInfo("phase_changed", PropertyInfo(Variant::INT, "new_phase")));
    ADD_SIGNAL(MethodInfo("game_ended", PropertyInfo(Variant::BOOL, "won")));
}

void SnakeLogic::set_direction(int dx, int dy) {
    Vector2i new_dir = Vector2i(dx, dy);
    if (new_dir + direction != Vector2i(0, 0)) {
        next_direction = new_dir;
    }
}

void SnakeLogic::setup(int width, int height) {
    grid_width = width;
    grid_height = height;
    score = 0;
    phase = 0;
    game_over = false;
    won = false;
    direction = Vector2i(1, 0);
    next_direction = Vector2i(1, 0);
    apples_since_last_wall = 0;
    light_radius = base_light_radius;
    move_speed = 0.15f;

    snake_body.clear();
    walls.clear();
    statues.clear();

    snake_body.push_back(Vector2i(width / 2, height / 2));
    snake_body.push_back(Vector2i(width / 2 - 1, height / 2));
    snake_body.push_back(Vector2i(width / 2 - 2, height / 2));

    spawn_apple();
}

Vector2i SnakeLogic::wrap_position(Vector2i pos) {
    pos.x = ((pos.x % grid_width) + grid_width) % grid_width;
    pos.y = ((pos.y % grid_height) + grid_height) % grid_height;
    return pos;
}

bool SnakeLogic::is_wall_at(Vector2i pos) {
    for (int i = 0; i < walls.size(); i++) {
        if ((Vector2i)walls[i] == pos) return true;
    }
    return false;
}

bool SnakeLogic::is_statue_at(Vector2i pos) {
    for (int i = 0; i < statues.size(); i++) {
        Dictionary s = statues[i];
        if ((Vector2i)s["pos"] == pos) return true;
    }
    return false;
}

bool SnakeLogic::is_occupied(Vector2i pos) {
    if (is_wall_at(pos)) return true;
    if (is_statue_at(pos)) return true;
    for (int i = 0; i < snake_body.size(); i++) {
        if ((Vector2i)snake_body[i] == pos) return true;
    }
    if (apple_pos == pos) return true;
    return false;
}

void SnakeLogic::spawn_apple() {
    Vector2i pos;
    int attempts = 0;
    do {
        pos = Vector2i(rand() % grid_width, rand() % grid_height);
        attempts++;
    } while (is_occupied(pos) && attempts < 200);
    apple_pos = pos;
}

void SnakeLogic::spawn_wall() {
    if (phase != 1) return;
    Vector2i head = (Vector2i)snake_body[0];
    Vector2i pos;
    int attempts = 0;
    do {
        pos = Vector2i(rand() % grid_width, rand() % grid_height);
        int dist = abs(pos.x - head.x) + abs(pos.y - head.y);
        bool too_close = dist <= 3;
        bool adj_wall = is_wall_at(Vector2i(pos.x+1,pos.y)) ||
                        is_wall_at(Vector2i(pos.x-1,pos.y)) ||
                        is_wall_at(Vector2i(pos.x,pos.y+1)) ||
                        is_wall_at(Vector2i(pos.x,pos.y-1));
        if (!too_close && !adj_wall && !is_occupied(pos)) break;
        attempts++;
    } while (attempts < 200);
    if (attempts < 200) walls.push_back(pos);
}

void SnakeLogic::update_statues() {
    for (int i = statues.size() - 1; i >= 0; i--) {
        Dictionary s = statues[i];
        if ((bool)s["is_filled"]) continue;
        int dur = (int)s["durability"] - 1;
        if (dur <= 0) {
            statues.remove_at(i);
        } else {
            s["durability"] = dur;
            statues[i] = s;
        }
    }
}

void SnakeLogic::update_phase() {
    int new_phase = 0;
    if (score >= 44) new_phase = 2;
    else if (score >= 22) new_phase = 1;

    if (new_phase != phase) {
        phase = new_phase;
        if (phase == 2) walls.clear();
        emit_signal("phase_changed", phase);
    }
}

bool SnakeLogic::step() {
    if (game_over) return false;

    direction = next_direction;
    Vector2i head = (Vector2i)snake_body[0];
    Vector2i new_head = wrap_position(head + direction);

    // self collision
    for (int i = 0; i < snake_body.size(); i++) {
        if ((Vector2i)snake_body[i] == new_head) {
            game_over = true;
            emit_signal("game_ended", false);
            return false;
        }
    }

    // wall collision phase 1
    if (phase == 1 && is_wall_at(new_head)) {
        game_over = true;
        emit_signal("game_ended", false);
        return false;
    }

    // statue collision phase 2
    if (phase == 2 && is_statue_at(new_head)) {
        game_over = true;
        emit_signal("game_ended", false);
        return false;
    }

    ate_last_step = (new_head == apple_pos);

    // move snake
    snake_body.insert(0, new_head);
    if (!ate_last_step) {
        // phase 2: tail becomes statue
        if (phase == 2) {
            Vector2i tail = (Vector2i)snake_body[snake_body.size() - 1];
            Dictionary statue;
            statue["pos"] = tail;
            statue["is_filled"] = false;
            statue["durability"] = 1 + (rand() % 2);
            statues.push_back(statue);
        }
        snake_body.remove_at(snake_body.size() - 1);
    }

    if (ate_last_step) {
        score += 2;
        light_radius = MIN(light_radius + 2.0f, max_light_radius);

        if (phase == 1) {
            apples_since_last_wall++;
            if (apples_since_last_wall % 2 == 1) spawn_wall();
        }

        if (phase == 2) {
            update_statues();
        }

        update_phase();
        spawn_apple();
        emit_signal("apple_eaten", score);

        if (score >= 68) { 
            won = true;
            game_over = true;
            emit_signal("game_ended", true);
            return false;
        }
    }

    if (light_radius > base_light_radius) {
        light_radius -= 0.1f;
        if (light_radius < base_light_radius) light_radius = base_light_radius;
    }

    return true;
}

void SnakeLogic::trim_to(int length) {
    while (snake_body.size() > length) {
        snake_body.remove_at(snake_body.size() - 1);
    }
}

void SnakeLogic::reset_for_pong() {
    game_over = false;
    won = false;
    phase = 0;
    apple_pos = Vector2i(-1, -1);
    walls.clear();
    statues.clear();
    UtilityFunctions::print("C++ reset_for_pong called, phase set to 0");
}

void SnakeLogic::clear_walls() { walls.clear(); }
void SnakeLogic::clear_statues() { statues.clear(); }

int SnakeLogic::get_score() const { return score; }
int SnakeLogic::get_phase() const { return phase; }
bool SnakeLogic::is_game_over() const { return game_over; }
bool SnakeLogic::is_won() const { return won; }
TypedArray<Vector2i> SnakeLogic::get_snake_body() const { return snake_body; }
Vector2i SnakeLogic::get_apple_pos() const { return apple_pos; }
TypedArray<Vector2i> SnakeLogic::get_walls() const { return walls; }
TypedArray<Dictionary> SnakeLogic::get_statues() const { return statues; }
float SnakeLogic::get_move_speed() const { return move_speed; }
float SnakeLogic::get_light_radius() const { return light_radius; }