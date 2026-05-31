#include "pong_game.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/typed_array.hpp>
#include <godot_cpp/variant/vector2i.hpp>
#include <cstdlib>
#include <cmath>

using namespace godot;

PongGame::PongGame() {
    grid_width = 20;
    grid_height = 20;
    player_score = 0;
    alex_score = 0;
    max_score = 7;
    game_over = false;
    player_won = false;
    ball_speed = 8.0f;
    alex_speed = 2.5f;
    alex_height = 4.0f;
    snake_hit_cooldown = 0.0f;
}

void PongGame::_bind_methods() {
    ClassDB::bind_method(D_METHOD("setup", "width", "height"), &PongGame::setup);
    ClassDB::bind_method(D_METHOD("step", "delta", "snake_body"), &PongGame::step);
    ClassDB::bind_method(D_METHOD("get_player_score"), &PongGame::get_player_score);
    ClassDB::bind_method(D_METHOD("get_alex_score"), &PongGame::get_alex_score);
    ClassDB::bind_method(D_METHOD("is_game_over"), &PongGame::is_game_over);
    ClassDB::bind_method(D_METHOD("is_player_won"), &PongGame::is_player_won);
    ClassDB::bind_method(D_METHOD("get_ball_pos"), &PongGame::get_ball_pos);
    ClassDB::bind_method(D_METHOD("get_alex_y"), &PongGame::get_alex_y);
    ClassDB::bind_method(D_METHOD("get_alex_height"), &PongGame::get_alex_height);

    ADD_SIGNAL(MethodInfo("point_scored", PropertyInfo(Variant::BOOL, "player_scored")));
    ADD_SIGNAL(MethodInfo("game_ended", PropertyInfo(Variant::BOOL, "player_won")));
}

void PongGame::setup(int width, int height) {
    grid_width = width;
    grid_height = height;
    player_score = 0;
    alex_score = 0;
    game_over = false;
    player_won = false;
    alex_y = height / 2.0f;
    alex_speed = 4.0f;
    snake_hit_cooldown = 0.0f;
    reset_ball(true);
}

void PongGame::reset_ball(bool player_scored) {
    ball_pos = Vector2(grid_width / 2.0f, grid_height / 2.0f);
    float angle = ((rand() % 60) - 30) * 3.14159f / 180.0f;
    float dir = player_scored ? 1.0f : -1.0f;
    ball_vel = Vector2(dir * cos(angle), sin(angle)) * ball_speed;
    snake_hit_cooldown = 0.0f;
}

bool PongGame::step(float delta, TypedArray<Vector2i> snake_body) {
    if (game_over) return false;

    // tick cooldown so we don't register multiple hits per frame
    if (snake_hit_cooldown > 0.0f) snake_hit_cooldown -= delta;

    // move ball
    ball_pos += ball_vel * delta;

    // bounce off top and bottom
    if (ball_pos.y <= 0) {
        ball_pos.y = 0;
        ball_vel.y = abs(ball_vel.y);
    }
    if (ball_pos.y >= grid_height) {
        ball_pos.y = grid_height;
        ball_vel.y = -abs(ball_vel.y);
    }

    // check snake body collision anywhere on board
    if (snake_hit_cooldown <= 0.0f) {
        int ball_cell_x = (int)ball_pos.x;
        int ball_cell_y = (int)ball_pos.y;
        for (int i = 0; i < snake_body.size(); i++) {
            Vector2i seg = (Vector2i)snake_body[i];
            if (abs(seg.x - ball_cell_x) <= 1 && abs(seg.y - ball_cell_y) <= 1) {
                // bounce rightward toward Alex
                ball_vel.x = abs(ball_vel.x);
                // add vertical angle based on where on the segment it hit
                ball_vel.y += (ball_pos.y - (float)seg.y) * 1.5f;
                ball_vel = ball_vel.normalized() * ball_speed;
                ball_pos.x = (float)seg.x + 1.5f; // push ball out of snake
                snake_hit_cooldown = 0.2f;
                break;
            }
        }
    }

    // left wall — alex scores (ball missed the snake)
    if (ball_pos.x <= 0) {
        alex_score++;
        emit_signal("point_scored", false);
        if (alex_score >= max_score) {
            game_over = true;
            player_won = false;
            emit_signal("game_ended", false);
            return false;
        }
        alex_speed += 0.3f;
        reset_ball(false);
    }

    // right wall — alex paddle
    if (ball_pos.x >= grid_width - 1.0f) {
        float alex_top = alex_y - alex_height / 2.0f;
        float alex_bot = alex_y + alex_height / 2.0f;
        if (ball_pos.y >= alex_top && ball_pos.y <= alex_bot) {
            ball_pos.x = grid_width - 1.0f;
            ball_vel.x = -abs(ball_vel.x);
            ball_speed += 0.2f;
            ball_vel = ball_vel.normalized() * ball_speed;
        } else {
            // player scores
            player_score++;
            emit_signal("point_scored", true);
            if (player_score >= max_score) {
                game_over = true;
                player_won = true;
                emit_signal("game_ended", true);
                return false;
            }
            reset_ball(true);
        }
    }

// alex AI — move toward ball, but only when ball is coming toward him
// and with some imprecision
// i needed to debuff her a bit because i lowkey suck at this and i didn't think this was winnable
float target = ball_pos.y + (((rand() % 3) - 1) * 1.5f); // ±1.5 cell imprecision
if (ball_vel.x > 0) { // only react when ball moving toward alex
    if (target < alex_y - 0.5f) {
        alex_y -= alex_speed * delta;
    } else if (target > alex_y + 0.5f) {
        alex_y += alex_speed * delta;
    }
}
alex_y = MAX(alex_height / 2.0f, MIN(alex_y, grid_height - alex_height / 2.0f));
    return true;
}

int PongGame::get_player_score() const { return player_score; }
int PongGame::get_alex_score() const { return alex_score; }
bool PongGame::is_game_over() const { return game_over; }
bool PongGame::is_player_won() const { return player_won; }
Vector2 PongGame::get_ball_pos() const { return ball_pos; }
float PongGame::get_alex_y() const { return alex_y; }
float PongGame::get_alex_height() const { return alex_height; }