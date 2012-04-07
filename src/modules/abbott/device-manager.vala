/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * device-manager.vala
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
    /**
     * Glucose Board Optium Xceed device manager class
     */
    [DBus (name = "org.freedesktop.GlucoseBoard.Module.Abbott.DeviceManager")]
    public class DeviceManager : GlucoseBoard.UDevDeviceManager
    {
        // types
        private struct Product
        {
            public string m_Name;
            public uint   m_VendorId;
            public int[]  m_ProductId;
        }

        // properties
        private GLib.DBusConnection  m_Connection;
        private GlucoseBoard.Config  m_Config;
        private Product[]            m_Meters;

        // accessors
        internal GLib.DBusConnection dbus_connection {
            get {
                return m_Connection;
            }
        }

        // signals
        public signal void glucose_meter_added ();
        public signal void glucose_meter_removed ();

        // methods
        construct
        {
            Log.debug_mc ("abbott", "device-manager", "Construct device manager");

            // Register our device type for usb subsystem
            register_device_type_for_subsystem ("usb", typeof (Device));

            // open config file
            try
            {
                m_Config = new GlucoseBoard.Config ("abbott.conf");

                m_Meters = {};
                string[] meters = m_Config.get_string_list ("General", "Meters");
                foreach (string meter in meters)
                {
                    Product product = Product ();
                    product.m_Name = meter;
                    product.m_VendorId = m_Config.get_integer_hex (meter, "VendorId");
                    product.m_ProductId = m_Config.get_integer_hex_list (meter, "ProductId");
                    m_Meters += product;
                }
            }
            catch (GlucoseBoard.ConfigError err)
            {
                Log.critical_mc ("abbott", "device", "Error on reading config: %s", err.message);
            }
        }

        /**
         * Create a new optium xceed device manager
         *
         * @param inConnection dbus connection
         */
        internal class DeviceManager (GLib.DBusConnection inConnection) throws DeviceManagerError
        {
            Log.debug_mc ("abbott", "device-manager", "Create device manager");

            string[] subsystems = { "usb", null };
            base (subsystems);

            // keep dbus connection
            m_Connection = inConnection;

            try
            {
                // register object on dbus
                m_Connection.register_object ("/org/freedesktop/GlucoseMeter/Module/Abbott/DeviceManager",
                                              this);

                // register added devices
                int n = 1;
                foreach (unowned GlucoseBoard.Device device in this)
                {
                    if (device is Device)
                    {
                        unowned Device? meter_device = (Device?)device;
                        meter_device.register (m_Connection, n);
                        ++n;
                    }
                }
            }
            catch (GLib.IOError err)
            {
                Log.error_mc ("abbott", "device-manager", "Error on register /org/freedesktop/GlucoseMeter/Module/Abbott/DeviceManager");
            }
        }

        private string?
        get_product_name (int inVendorId, int inProductId)
        {
            Log.debug_mc ("abbott", "module", GLib.Log.METHOD);

            foreach (Product product in m_Meters)
            {
                if (product.m_VendorId == inVendorId)
                {
                    foreach (int product_id in product.m_ProductId)
                    {
                        if (product_id == inProductId)
                            return product.m_Name;
                    }
                }
            }

            return null;
        }

        /**
         * {@inheritDoc}
         */
        internal override GlucoseBoard.Device?
        create_device (string inSubsystem, string inPath, string inName,
                       uint inVendorId, uint inProductId) throws DeviceManagerError
        {
            Log.debug_mc ("abbott", "device-manager", "%s %s %s", GLib.Log.METHOD, inPath, inName);

            if (inSubsystem == "usb")
            {
                string? product_name = get_product_name ((int)inVendorId, (int)inProductId);
                if (product_name != null)
                {
                    Log.info_mc ("abbott", "device", "found blood meter %s at %s 0x%04x:0x%04x", product_name, inSubsystem, inVendorId, inProductId);
                    return base.create_device (inSubsystem, inPath, product_name, inVendorId, inProductId);
                }
            }

            return null;
        }

        /**
         * {@inheritDoc}
         */
        internal override void
        on_device_added (GlucoseBoard.Device inDevice)
        {
            Log.debug_mc ("abbott", "device-manager", GLib.Log.METHOD);

            // call parent methods
            base.on_device_added (inDevice);

            // register device
            if (inDevice is Device && m_Connection != null)
            {
                unowned Device? device = (Device?)inDevice;
                device.register (m_Connection, length);

                // emit meter added
                glucose_meter_added ();
            }
        }

        /**
         * {@inheritDoc}
         */
        internal override void
        on_device_removed (string inDevicePath)
        {
            Log.debug_mc ("abbott", "device-manager", GLib.Log.METHOD);

            unowned GlucoseBoard.Device? device = this[inDevicePath];
            bool send_signal = device != null;
            if (device is Device)
            {
                ((Device)device).unregister ();
            }

             // call parent methods
            base.on_device_removed (inDevicePath);

            if (send_signal)
            {
                // emit meter removed
                glucose_meter_removed ();
            }
        }

        /**
         * Return the list of device managed by device manager
         *
         * @return string array of device name managed by device manager
         */
        public string[]
        get_device_list ()
        {
            Log.debug_mc ("abbott", "device-manager", GLib.Log.METHOD);

            string[] names = {};

            foreach (unowned GlucoseBoard.Device device in this)
            {
                if (device is Device)
                {
                    names += ((Device)device).dbus_name;
                }
            }

            return names;
        }
    }
}
