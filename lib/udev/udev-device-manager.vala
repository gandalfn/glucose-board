/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * udev-device-manager.vala
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
     * This class provides the devices list from UDev
     */
    public class UDevDeviceManager : DeviceManager
    {
        // static properties
        private const string s_PropertyNames [] = {
            "ID_VENDOR_FROM_DATABASE",
            "ID_MODEL",
            "ID_VENDOR_ID",
            "ID_MODEL_ID"
        };

        // properties
        private GUdev.Client m_Client;

        // methods
        construct
        {
            register_device_type_for_subsystem ("usb", typeof (UsbDevice));
        }

        /**
         * Create a UDev device manager
         *
         * @param inSubsystems List of subsystems
         *
         * @throws DeviceManagerError raised when something went wrong
         */
        [CCode (array_null_terminated = true)]
        public UDevDeviceManager (string[] inSubsystems) throws DeviceManagerError
        {
            // Create object
            GLib.Object (subsystems: inSubsystems);

            // Create hal context
            m_Client = new GUdev.Client (inSubsystems);

            // Connect on udev event
            m_Client.uevent.connect (on_udev_uevent);

            // Parse all devices
            foreach (unowned string subsystem in inSubsystems)
            {
                foreach (unowned GUdev.Device device in m_Client.query_by_subsystem (subsystem))
                {
                    add_device (device.get_sysfs_path ());
                }
            }
        }

        private void
        on_udev_uevent (string inAction, GUdev.Device inDevice)
        {
            Log.debug ("Udev action %s", inAction);
            try
            {
                switch (inAction)
                {
                    case "add":
                        add_device (inDevice.get_sysfs_path ());
                        break;

                    case "remove":
                        remove_device (inDevice.get_sysfs_path ());
                        break;

                    default:
                        break;
                }
            }
            catch (DeviceManagerError err)
            {
                Log.error ("Error on %s device: %s", inAction, err.message);
            }
        }

        /**
         * {@inheritDoc}
         */
        protected override unowned string?
        matching_subsystem (string inDeviceFile) throws DeviceManagerError
        {
            unowned string? ret = null;
            GUdev.Device? device = m_Client.query_by_sysfs_path (inDeviceFile);

            if (device != null)
            {
                unowned string? udi_subsystem = device.get_subsystem ();

                if (udi_subsystem != null)
                {
                    foreach (unowned string subsystem in subsystems)
                    {
                        if (udi_subsystem == subsystem)
                        {
                            return subsystem;
                        }
                    }
                }
            }

            return ret;
        }

        /**
         * {@inheritDoc}
         */
        protected override void
        add_device (string inDeviceFile) throws DeviceManagerError
        {
            unowned string? device_subsystem = matching_subsystem (inDeviceFile);

            if (device_subsystem != null)
            {
                string name = get_device_name (inDeviceFile);
                uint vendor_id = (uint)get_device_property_integer (inDeviceFile, get_property_name (device_subsystem, Device.Property.VENDOR_ID));
                uint product_id = (uint)get_device_property_integer (inDeviceFile, get_property_name (device_subsystem, Device.Property.PRODUCT_ID));
                Device? device = create_device(device_subsystem, inDeviceFile, name, vendor_id, product_id);

                if (device != null) on_device_added (device);
            }
        }

        /**
         * {@inheritDoc}
         */
        protected override void
        remove_device (string inDeviceFile) throws DeviceManagerError
        {
            on_device_removed (inDeviceFile);
        }

        /**
         * {@inheritDoc}
         */
        public override string
        get_property_name (string inSubsection, Device.Property inProperty) throws DeviceManagerError
            requires ((int)inProperty < s_PropertyNames.length)
        {
            return s_PropertyNames[inProperty];
        }

        /**
         * {@inheritDoc}
         */
        public string
        get_device_name (string inDeviceFile) throws DeviceManagerError
        {
            GUdev.Device? device = m_Client.query_by_sysfs_path (inDeviceFile);
            if (device == null)
            {
                throw new DeviceManagerError.GET_PROPERTY ("Device not found");
            }

            return device.get_name ();
        }

        /**
         * {@inheritDoc}
         */
        public override string
        get_device_property_string (string inDeviceFile, string inProperty) throws DeviceManagerError
        {
            GUdev.Device? device = m_Client.query_by_sysfs_path (inDeviceFile);
            if (device == null)
            {
                throw new DeviceManagerError.GET_PROPERTY ("Device not found");
            }

            string ret = device.get_property (inProperty);
            if (ret == null)
            {
                throw new DeviceManagerError.GET_PROPERTY ("Device property %s not found", inProperty);
            }
            return ret;
        }

        /**
         * {@inheritDoc}
         */
        public override int
        get_device_property_integer (string inDeviceFile, string inProperty) throws DeviceManagerError
        {
            GUdev.Device? device = m_Client.query_by_sysfs_path (inDeviceFile);
            if (device == null)
            {
                throw new DeviceManagerError.GET_PROPERTY ("Device not found");
            }

            int val = 0;
            string str = device.get_property (inProperty);
            if (str != null) str.scanf ("%x", out val);

            return val;
        }
    }
}
