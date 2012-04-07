/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * module.vala
 * Copyright (C) Nicolas Bruguier 2012 <gandalfn@club-internet.fr>
 *
 * glucose-board is free software: you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * glucose-board is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace GlucoseBoard.Module.Abbott
{
    [DBus (name = "org.freedesktop.GlucoseBoard.Module.Abbott")]
    internal class Module : GlucoseBoard.DBusModule
    {
        // properties
        private DeviceManager m_DeviceManager;

        // methods
        construct
        {
            try
            {
                m_DeviceManager = new DeviceManager (dbus_connection);
            }
            catch (GlucoseBoard.DeviceManagerError err)
            {
                Log.critical_mc ("abbott", "module", "Error on create Abbott manager: %s", err.message);
            }
        }
    }
}

public GLib.Type plugin_init (GLib.Module inModule)
{
    return typeof (GlucoseBoard.Module.Abbott.Module);
}
