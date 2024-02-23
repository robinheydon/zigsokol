const std = @import("std");
const sokol = @import("sokol");
const sapp = sokol.app;
const sg = sokol.gfx;
const sgl = sokol.gl;
const sgapp = sokol.app_gfx_glue;
const stm = sokol.time;

var pass_action : sg.PassAction = .{};
var last_now : f64 = 0;
var delta_time : f64 = 0;

export fn init () void
{
    sg.setup (.{
        .context = sgapp.context (),
        .logger = .{ .func = sokol.log.func },
    });

    pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.4, .g = 0.4, .b = 0.4, .a = 1 },
    };

    sgl.setup (.{});
    stm.setup ();

    std.debug.print ("{}\n", .{sg.queryBackend()});
}

export fn cleanup () void
{
    stm.setup ();
    sgl.shutdown ();
    sg.shutdown ();
}

fn get_now () f64
{
    const now = stm.now ();
    const secs = stm.stm_sec (now);
    return secs;
}

fn draw_square (width: f32, height: f32) void
{
    sgl.beginQuads ();
    sgl.v2fC3b (0, 0, 255, 0, 0);
    sgl.v2fC3b (width, 0, 0, 255, 0);
    sgl.v2fC3b (width, height, 0, 0, 255);
    sgl.v2fC3b (0, height, 0, 255, 255);
    sgl.end ();
}

fn draw_frame_times (width: f32, height: f32) void
{
    const bar_height : f32 = @floatCast (height - height * delta_time * 60);

    sgl.beginQuads ();
    sgl.v2fC3b (0, bar_height, 1, 0, 0);
    sgl.v2fC3b (width - 1, bar_height, 1, 0, 0);
    sgl.v2fC3b (width - 1, height - 1, 1, 0, 0);
    sgl.v2fC3b (0, height - 1, 1, 0, 0);
    sgl.end ();

    sgl.beginLineStrip ();
    sgl.v2fC3b (0, 0, 1, 0, 0);
    sgl.v2fC3b (width - 1, 0, 1, 0, 0);
    sgl.v2fC3b (width - 1, height - 1, 0, 0, 0);
    sgl.v2fC3b (0, height - 1, 1, 0, 0);
    sgl.v2fC3b (0, 0, 1, 0, 0);
    sgl.end ();

    sgl.beginLineStrip ();
    sgl.v2fC3b (0, 0, 0, 1, 0);
    sgl.v2fC3b (width - 1, 0, 0, 1, 0);
    sgl.v2fC3b (width - 1, bar_height, 0, 1, 0);
    sgl.v2fC3b (0, bar_height, 0, 1, 0);
    sgl.v2fC3b (0, 0, 0, 1, 0);
    sgl.end ();
}

export fn frame () void
{
    const now = get_now ();
    delta_time = now - last_now;
    // const fps = 1 / dt;
    last_now = now;
    // std.debug.print ("{d:16.9} {d:16.9} {d}\r", .{now, dt, fps});

    const width = sapp.widthf ();
    const height = sapp.heightf ();

    sgl.viewportf (0, 0, width, height, true);
    sgl.defaults ();
    sgl.ortho (0, width, height, 0, -1, 1);

    sgl.pushMatrix ();
    sgl.translate (200, 250, 0);
    sgl.rotate (@floatCast (now), 0, 0, 1);
    draw_square (100, 100);
    sgl.popMatrix ();

    sgl.pushMatrix ();
    sgl.translate (150, 100, 0);
    sgl.rotate (@floatCast (delta_time * 40), 0, 0, 1);
    draw_square (100, 100);
    sgl.popMatrix ();

    draw_frame_times (16, height);

    sg.beginDefaultPass (pass_action, sapp.width (), sapp.height ());

    sgl.draw ();

    sg.endPass ();

    sg.commit ();
}

export fn event (cev: [*c]const sapp.Event) void
{
    const ev = cev.*;

    switch (ev.type)
    {
        .KEY_DOWN => on_key_down (ev),
        .KEY_UP => on_key_up (ev),
        .CHAR => on_key_char (ev),
        .MOUSE_MOVE => on_mouse_move (ev),
        .MOUSE_DOWN => on_mouse_down (ev),
        .MOUSE_UP => on_mouse_up (ev),
        .MOUSE_LEAVE => on_mouse_leave (ev),
        .MOUSE_ENTER => on_mouse_enter (ev),
        .FOCUSED => on_focused (ev),
        .UNFOCUSED => on_unfocused (ev),
        .ICONIFIED => on_iconified (ev),
        .RESTORED => on_restored (ev),
        .QUIT_REQUESTED => on_quit_requested (ev),
        .RESIZED => on_resized (ev),
        else => {
            std.debug.print ("Event: {}\n", .{ev.type});
        },
    }
}

fn on_key_down (ev: sapp.Event) void
{
    // std.debug.print ("Key: {} Mod: {} Repeat: {}\n", .{ev.key_code, ev.modifiers, ev.key_repeat});

    if (ev.key_code == .ESCAPE and ev.modifiers == 0)
    {
        sapp.requestQuit ();
    }
    else if (ev.key_code == .F11 and ev.modifiers == 0)
    {
        sapp.toggleFullscreen ();
    }
}

fn on_key_up (ev: sapp.Event) void
{
    _ = ev;
}

fn on_key_char (ev: sapp.Event) void
{
    _ = ev;
    // std.debug.print ("Key: {x:0>4}\n", .{ev.char_code});
}

fn on_mouse_move (ev: sapp.Event) void
{
    _ = ev;
    if (sapp.mouseLocked ())
    {
        // std.debug.print ("MouseLock: {d},{d}\n", .{ev.mouse_dx, ev.mouse_dy});
    }
    else
    {
        // std.debug.print ("MouseMove: {d},{d}\n", .{ev.mouse_x, ev.mouse_y});
    }
}

fn on_mouse_down (ev: sapp.Event) void
{
    _ = ev;
    // sapp.lockMouse (true);
}

fn on_mouse_up (ev: sapp.Event) void
{
    // sapp.lockMouse (false);
    _ = ev;
}

fn on_mouse_enter (ev: sapp.Event) void
{
    _ = ev;
}

fn on_mouse_leave (ev: sapp.Event) void
{
    _ = ev;
}

fn on_focused (ev: sapp.Event) void
{
    _ = ev;
}

fn on_unfocused (ev: sapp.Event) void
{
    _ = ev;
}

fn on_quit_requested (ev: sapp.Event) void
{
    _ = ev;
}

fn on_iconified (ev: sapp.Event) void
{
    _ = ev;
}

fn on_restored (ev: sapp.Event) void
{
    _ = ev;
}

fn on_resized (ev: sapp.Event) void
{
    _ = ev;

    // std.debug.print ("\nResize {}x{}\n", .{ev.window_width, ev.window_height});
}

pub fn main() !void {
    std.debug.print ("\n", .{});
    sapp.run (.{
        .init_cb = init,
        .frame_cb = frame,
        .event_cb = event,
        .cleanup_cb = cleanup,
        .width = 1280,
        .height= 720,
        .window_title = "Test",
        .logger = .{ .func = sokol.log.func },
    });
}
