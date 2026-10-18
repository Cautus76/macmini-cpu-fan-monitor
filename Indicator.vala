public class CpuMonitor.Indicator : Wingpanel.Indicator {
    private Gtk.Label? label;
    private Gtk.Box? popup;
    private Gtk.Label? details;
    private bool busy = false;
    private string current = "CPU …";

    public Indicator () {
        Object (code_name: "cpu-monitor");
    }

    construct {
        visible = true;
        GLib.Timeout.add_seconds (5, () => {
            refresh ();
            return GLib.Source.CONTINUE;
        });
    }

    private void refresh () {
        if (busy) return;
        busy = true;
        new GLib.Thread<void*> ("cpu-monitor-refresh", () => {
            string output = "";
            string err = "";
            int exit_status = 0;
            bool ok = false;
            try {
                string path = GLib.Environment.get_home_dir () + "/.local/share/cpu-monitor/cpu-monitor.py";
                string[] args = { "/usr/bin/python3", path };
                GLib.Process.spawn_sync (null, args, null, GLib.SpawnFlags.SEARCH_PATH,
                                         null, out output, out err, out exit_status);
                ok = exit_status == 0 && output.strip () != "";
            } catch (GLib.SpawnError e) {
                // Leave the label in its unavailable state.
            }
            string result = ok ? output.strip () : "CPU: nedostupné";
            GLib.Idle.add (() => {
                current = result;
                if (label != null) label.label = current;
                if (details != null) details.label = current;
                busy = false;
                return GLib.Source.REMOVE;
            });
            return null;
        });
    }

    public override void opened () { refresh (); }
    public override void closed () { }

    public override Gtk.Widget get_display_widget () {
        if (label == null) {
            label = new Gtk.Label (current);
            label.margin_start = 8;
            label.margin_end = 8;
            label.show ();
            refresh ();
        }
        return label;
    }

    public override Gtk.Widget? get_widget () {
        if (popup == null) {
            popup = new Gtk.Box (Gtk.Orientation.VERTICAL, 8);
            popup.margin = 12;
            details = new Gtk.Label (current);
            popup.pack_start (details, false, false, 0);
            popup.show_all ();
        }
        return popup;
    }
}

public Wingpanel.Indicator? get_indicator (GLib.Module module, Wingpanel.IndicatorManager.ServerType server_type) {
    if (server_type != Wingpanel.IndicatorManager.ServerType.SESSION) return null;
    return new CpuMonitor.Indicator ();
}

