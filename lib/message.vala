/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * message.vala
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
     * This class provides the message abstraction for send to device
     */
    public class Message : GLib.Object
    {
        // properties
        private uint8[] m_Raw;
        private int m_Length;

        // accessors
        public uint8[] raw {
            get {
                return m_Raw;
            }
        }

        public int length {
            get {
                return m_Length;
            }
            set {
                m_Length = value;
            }
        }

        // methods
        /**
         * Provides the message abstraction for send to device
         *
         * @param inLength The number of bytes of the message
         */
         public Message (uint inLength)
         {
            m_Raw = new uint8[inLength];
         }

        /**
         * Provides the message abstraction for send to device
         *
         * @param inBuffer This buffer contains the message.
         * @param inOffset The offset of the message in the buffer.
         * @param inLength The number of bytes of the message.
         */
        public Message.from_data (uint8[] inBuffer, uint inOffset = 0, uint inLength = -1)
        {
            if (inLength < 0) inLength = inBuffer.length;
            m_Raw = new uint8[inLength - inOffset];
            GLib.Memory.copy (m_Raw, &inBuffer[inOffset], sizeof (uint8) * inLength);
        }

        /**
         * Return the string representation of the message.
         *
         * @param inOffset The offset where to begin display in message
         * @param inNumBytes The number of bytes to display
         *
         * @return the string representation of the message
         */
        public string
        to_string (uint inOffset = 0, uint inNumBytes = 0)
        {
            if (inNumBytes == 0) inNumBytes = m_Length;

            GLib.StringBuilder builder = new GLib.StringBuilder();

            builder.append("%02x".printf (m_Raw[inOffset++]));

            if (inNumBytes > 1)
            {
                for (int counter = 1; counter < inNumBytes; counter++)
                {
                    builder.append(" ");
                    builder.append("%02x".printf (m_Raw[inOffset++]));
                }
            }
            return builder.str;
        }

        /**
         * Return the string raw representation of the message.
         *
         * @param inOffset The offset where to begin display in message
         * @param inNumBytes The number of bytes to display
         *
         * @return the string raw representation of the message
         */
        public string
        to_raw_string (uint inOffset = 0, uint inNumBytes = 0)
            requires (inOffset + inNumBytes < m_Raw.length)
        {
            if (inNumBytes == 0) inNumBytes = m_Length;

            GLib.StringBuilder builder = new GLib.StringBuilder ();

            for (uint cpt = inOffset; cpt < inNumBytes; ++cpt)
            {
                if (m_Raw[cpt] > 0)
                    builder.append_c ((char)m_Raw[cpt]);
            }

            return builder.str;
        }

        /**
         * Get value at inIndex
         *
         * @param inIndex position index of value to get
         *
         * @return value
         */
        public new uint8
        @get (uint inIndex)
            requires (inIndex < m_Raw.length)
        {
            return m_Raw[inIndex];
        }

        /**
         * Set inValue at inPos
         *
         * @param inIndex position index of value to set
         * @param inValue the new value
         */
        public new void
        set (uint inIndex, uint8 inValue)
            requires (inIndex < m_Raw.length)
        {
            m_Length = int.max (m_Length, (int)inIndex + 1);
            m_Raw[inIndex] = inValue;
        }

        /**
         * Get value at inIndex
         *
         * @param inIndex position index of value to get
         *
         * @return value
         */
        public uint32
        get_uint32 (uint inIndex)
            requires (inIndex + 3 < m_Raw.length)
        {
            uint32 ret = 0;
            ret |= (uint32)(m_Raw[inIndex + 3] << 24);
            ret |= (uint32)(m_Raw[inIndex + 2] << 16);
            ret |= (uint32)(m_Raw[inIndex + 1] << 8);
            ret |= (uint32)m_Raw[inIndex  + 0];

            return ret;
        }

        /**
         * Set inValue at inPos
         *
         * @param inIndex position index of value to set
         * @param inValue the new value
         */
        public void
        set_uint32 (uint inIndex, uint32 inValue)
            requires (inIndex + 3 < m_Raw.length)
        {
            m_Length = int.max (m_Length, (int)inIndex + 4);
            m_Raw[inIndex + 3] = (uint8)((inValue >> 24) & 0xff);
            m_Raw[inIndex + 2] = (uint8)((inValue >> 16) & 0xff);
            m_Raw[inIndex + 1] = (uint8)((inValue >> 8) & 0xff);
            m_Raw[inIndex + 0] = (uint8)(inValue & 0xff);
        }

        /**
         * Get value at inIndex
         *
         * @param inIndex position index of value to get
         *
         * @return value
         */
        public uint16
        get_uint16 (uint inIndex)
            requires (inIndex + 1 < m_Raw.length)
        {
            uint16 ret = 0;
            ret |= (uint16)(m_Raw[inIndex + 1] << 8);
            ret |= (uint16)m_Raw[inIndex + 0];

            return ret;
        }

        /**
         * Set inValue at inPos
         *
         * @param inIndex position index of value to set
         * @param inValue the new value
         */
        public void
        set_uint16 (uint inIndex, uint16 inValue)
            requires (inIndex + 1 < m_Raw.length)
        {
            m_Length = int.max (m_Length, (int)inIndex + 2);
            m_Raw[inIndex + 1] = (uint8)((inValue >> 8) & 0xff);
            m_Raw[inIndex + 0] = (uint8)(inValue & 0xff);
        }

        /**
         * Get array at inIndex
         *
         * @param inIndex position index of array to get
         *
         * @return value
         */
        public uint8[]
        get_array (uint inIndex)
            requires (inIndex < m_Raw.length)
        {
            uint8[] ret = {};

            foreach (uint8 val in m_Raw)
            {
                ret += val;
            }

            return ret;
        }

        /**
         * Set array at inIndex
         *
         * @param inIndex position index of array to get
         * @param inArray the new array value
         * @param inNumBytes the number of bytes to copy
         *
         * @return value
         */
        public void
        set_array (uint inIndex, uint8[] inArray, uint inNumBytes = 0)
        {
            GLib.return_if_fail (inIndex + (inNumBytes == 0 ? inArray.length : inNumBytes) <= m_Raw.length);

            m_Length = (int)inIndex + (int)(inNumBytes == 0 ? inArray.length : inNumBytes);
            GLib.Memory.copy (&m_Raw[inIndex], inArray, sizeof (uint8) * (inNumBytes == 0 ? inArray.length : inNumBytes));
        }

        /**
         * Copy data inMessage in this
         *
         * @param inMessage message to copy to
         * @param inValue the new value
         */
        public void
        copy (Message inMessage)
            requires (inMessage.m_Raw.length <= m_Raw.length)
        {
            m_Length = inMessage.m_Length;
            GLib.Memory.copy (m_Raw, inMessage.m_Raw, sizeof (uint8) * inMessage.m_Raw.length);
        }
    }
}
