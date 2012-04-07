/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * freedesktop.vala
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

namespace FreeDesktop
{
    public enum DBusRequestNameReply
    {
        PRIMARY_OWNER = 1,
        IN_QUEUE,
        EXISTS,
        ALREADY_OWNER
    }

    [DBus (name = "org.freedesktop.DBus")]
    public interface DBusObject : GLib.Object
    {
        public abstract signal void name_owner_changed (string name, string old_owner, string new_owner);
        public abstract uint32 request_name (string name, uint32 flags) throws DBus.Error;
    }
}
