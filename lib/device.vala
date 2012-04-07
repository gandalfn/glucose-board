/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * device.vala
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

namespace GlucoseBoard
{
    /**
     * This class provides extended information for each device.
     */
    public abstract class Device : GLib.Object
    {
        // type
        public enum Property
        {
            VENDOR,
            PRODUCT,
            VENDOR_ID,
            PRODUCT_ID,

            N
        }

        // accessors
        /**
         * Identification string of the device.
         */
        public abstract string path { get; construct set; default = null; }

        /**
         * Name of the device.
         */
        public abstract string name { get; construct set; default = null; }

        /**
         * The vendor identification number of the device.
         */
        public abstract uint vendor_id { get; construct set; default = 0xFFFF; }

        /**
         * The product identification number of the device.
         */
        public abstract uint product_id { get; construct set; default = 0xFFFF; }

        // methods
        /**
         * Returns the string representation of device
         *
         * @return string representation of device
         */
        public abstract string to_string ();

        /**
         * Compare the device with inOther
         *
         * @param inOther device to compare to
         *
         * @return less than 0 if device is less than inOther, greater than 0 if device is greater than inOther , 0 if devices are equal
         */
        public virtual int
        compare (Device inOther)
        {
            return GLib.strcmp (path, inOther.path);
        }
    }
}
