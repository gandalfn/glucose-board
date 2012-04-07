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

namespace GlucoseBoard
{
    public errordomain DeviceManagerError
    {
        INIT,
        CREATE_DEVICE,
        NOT_FOUND,
        GET_DEVICES,
        GET_PROPERTY,
        ADD,
        REMOVE,
        NOT_IMPLEMENTED
    }

    /**
     * This class manage a list of attached devices for a subsystem.
     */
    public abstract class DeviceManager : GLib.Object
    {
        // types
        public class Iterator : GLib.Object
        {
            // properties
            private DeviceManager                     m_Manager;
            private GLib.List<unowned string>         m_PathList = null;
            private unowned GLib.List<unowned string> m_Index = null;

            // methods
            internal Iterator (DeviceManager inManager)
            {
                m_Manager = inManager;
                if (m_Manager.m_AttachedDevices != null)
                {
                    m_PathList = m_Manager.m_AttachedDevices.get_keys ();
                }
            }

            /**
             * Advances to the next device in the device list.
             *
             * @return ``true`` if the iterator has a next device
             */
            public bool
            next ()
            {
                if (m_Index == null)
                {
                    m_Index = m_PathList;
                }
                else
                {
                    m_Index = m_Index.next;
                }

                return m_Index != null;
            }

            /**
             * Returns the current device in the device list.
             *
             * @return the current device in the device list
             */
            public new unowned Device?
            get ()
            {
                return m_Manager[m_Index.data];
            }
        }

        // properties
        private GLib.HashTable<string, GLib.Type?> m_SubsystemDeviceType = null;
        private GLib.HashTable<string, Device> m_AttachedDevices = null;

        // accessors
        /**
         * The devices subsystem
         */
        [CCode (array_null_terminated = true)]
        public string[] subsystems { get; construct; default = null; }

        /**
         * The number of devices
         */
        public uint length {
            get {
                return m_AttachedDevices != null ? m_AttachedDevices.size () : 0;
            }
        }

        // signals
        /**
         * This signal is emitted, when a new device is attached to subsystem
         *
         * @param inDevice the path of device attached to subsystem
         */
        public signal void added (string inDevicePath);

        /**
         * This signal is emitted, when a device is removed from subsystem
         *
         * @param inDevice the path of device removed from subsystem
         */
        public signal void removed (string inDevicePath);

        // methods
        /**
         * This function a device type for a subsystem name
         *
         * @param inSubsystem subsystem name
         * @param inType the device type to be created
         */
        protected void
        register_device_type_for_subsystem (string inSubsystem, GLib.Type inType)
            requires (inType.is_a (typeof (Device)))
        {
            if (m_SubsystemDeviceType == null)
            {
                m_SubsystemDeviceType = new GLib.HashTable<string, GLib.Type?> (GLib.str_hash, GLib.str_equal);
            }

            m_SubsystemDeviceType.insert (inSubsystem, inType);
        }

        /**
         * Create a new device for the corresponding subsystem. The type of device depends from
         * device registered with @see register_device_type_for_subsystem
         *
         * @param inSubsystem the subsystem for which we create the device
         * @param inPath the path of the new device
         * @param inName the name of the new device
         * @param inVendorId the vendor id of the new device
         * @param inProductId the product id of the new device
         *
         * @return the newly created device
         *
         * @throws DeviceManagerError raised when somethings went wrong
         */
        public virtual Device?
        create_device (string inSubsystem, string inPath, string inName,
                       uint inVendorId, uint inProductId) throws DeviceManagerError
        {
            if (m_SubsystemDeviceType == null)
            {
                throw new DeviceManagerError.CREATE_DEVICE ("No device type registered");
            }

            GLib.Type? type = m_SubsystemDeviceType.lookup (inSubsystem);
            if (type == null)
            {
                throw new DeviceManagerError.CREATE_DEVICE ("No device type registered for subsystem %s", inSubsystem);
            }

            return GLib.Object.new (type, path: inPath, name: inName,
                                    vendor_id: inVendorId, product_id: inProductId) as Device;
        }

        /**
         * This function should be called by the derived class, when a device was added.
         *
         * @param inDevice the new device added to manager
         */
        protected virtual void
        on_device_added (Device inDevice)
        {
            if (m_AttachedDevices == null)
            {
                m_AttachedDevices = new GLib.HashTable<string, Device> (GLib.str_hash, GLib.str_equal);
            }

            m_AttachedDevices.insert (inDevice.path, inDevice);

            added (inDevice.path);

            Log.debug ("Device %s added", inDevice.path);
        }

        /**
         * This function should be called by the derived class, when a device was removed.
         *
         * @param inDevicePath the path of the device removed
         */
        protected virtual void
        on_device_removed (string inDevicePath)
        {
            if (m_AttachedDevices.lookup (inDevicePath) != null)
            {
                m_AttachedDevices.remove (inDevicePath);
                removed (inDevicePath);

                Log.debug ("Device %s removed", inDevicePath);
            }
        }

        /**
         * This function should be implemented by derived class, to check device match device manager subsystem.
         *
         * @param inDevicePath the path of the device to be checked
         *
         * @return the corresponding device manager subsystem if device match, else null
         */
        protected virtual unowned string?
        matching_subsystem (string inDevicePath) throws DeviceManagerError
        {
            throw new DeviceManagerError.NOT_IMPLEMENTED ("not implemented for %s", get_type ().name ());
        }

        /**
         * This function should be implemented by derived class, to add device to manager.
         *
         * @param inDevicePath the path of the device to be added
         *
         * @throws DeviceManagerError raised when somethings went wrong
         */
        protected abstract void add_device (string inDevicePath) throws DeviceManagerError;

        /**
         * This function should be implemented by derived class, to remove device from manager.
         *
         * @param inDevicePath the path of the device to be removed
         *
         * @throws DeviceManagerError raised when somethings went wrong
         */
        protected abstract void remove_device (string inDevicePath) throws DeviceManagerError;

        /**
         * Get string property of a device
         *
         * @param inDevicePath the path of the device
         * @param inProperty the property of the device
         *
         * @return the string property of the device
         *
         * @throws DeviceManagerError raised when somethings went wrong
         */
        public virtual string
        get_device_property_string (string inDevicePath, string inProperty) throws DeviceManagerError
        {
            throw new DeviceManagerError.NOT_IMPLEMENTED ("not implemented for %s", get_type ().name ());
        }

        /**
         * Get integer property of a device
         *
         * @param inDevicePath the path of the device
         * @param inProperty the property of the device
         *
         * @return the integer property of the device
         *
         * @throws DeviceManagerError raised when somethings went wrong
         */
        public virtual int
        get_device_property_integer (string inDevicePath, string inProperty) throws DeviceManagerError
        {
            throw new DeviceManagerError.NOT_IMPLEMENTED ("not implemented for %s", get_type ().name ());
        }

        /**
         * Returns the device property name corresponding to inSubsection and inProperty
         *
         * @param inSubsection subsection name
         * @param inProperty a @see Device.Property type
         *
         * @return the device property name
         */
        public virtual string
        get_property_name (string inSubsection, Device.Property inProperty) throws DeviceManagerError
        {
            throw new DeviceManagerError.NOT_IMPLEMENTED ("not implemented for %s", get_type ().name ());
        }

        /**
         * This function check if device manager already have the device.
         *
         * @param inDevice the vendor id of the device to search
         * @param inProductId the product id of the device to search
         *
         * @return ``true`` if a device corresponding is found
         */
        public bool
        contains (Device inDevice)
        {
            foreach (unowned Device? device in this)
            {
                if (device.compare (inDevice) == 0)
                    return true;
            }

            return false;
        }

        /**
         * This function return the device in the manager corresponding to inDevicePath.
         *
         * @param inDevicePath the path of the device
         *
         * @return the device associated to inDevicePath if found, else null
         */
        public new unowned Device?
        @get (string inDevicePath)
        {
            return m_AttachedDevices != null ? m_AttachedDevices.lookup (inDevicePath) : null;
        }

        /**
         * Returns a {@link Iterator} that can be used for simple iteration over the
         * device list.
         *
         * @return a {@link Iterator} that can be used for simple iteration over the
         *         device list.
         */
        public Iterator
        iterator ()
        {
            return new Iterator (this);
        }
    }
}
