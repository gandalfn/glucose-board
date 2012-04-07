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

namespace GlucoseBoard.Module.Abbott
{
    public class Message : GlucoseBoard.Message
    {
        private enum Commands
        {
            STX  = 0x02,
            ETX  = 0x03,
            EOT  = 0x04,
            ENQ  = 0x05,
            ACK  = 0x06,
            CR   = 0x0D,
            LF   = 0x0A,
            NACK = 0x15,
            ETB  = 0x17
        }

        public bool is_ack {
            get {
                return this[0] == Commands.ACK;
            }
        }

        public Message (uint inLength = 1)
        {
            base (inLength);
        }

        public Message.query_id ()
        {
            base (9);
            this[0] = (uint8)Commands.STX;
            this[1] = '1';
            this[2] = 'I';
            this[3] = 'D';
            this[4] = (uint8)Commands.ETX;
            this[7] = (uint8)Commands.CR;
            this[8] = (uint8)Commands.LF;

            int checksum = (int)(this[1] + this[2] + this[3] + this[4]);
            string crc = "%02x".printf (checksum & 0xFF);
            set_array (5, (uint8[])crc, 2);
        }

        public Message.mem ()
        {
            base (4);
            this[1] = 'm';
            this[2] = 'e';
            this[3] = 'm';
        }

        public Message.xmem ()
        {
            base (8);
            this[1] = 0x24;
            this[2] = 'x';
            this[3] = 'm';
            this[4] = 'e';
            this[5] = 'm';
            this[6] = (uint8)Commands.CR;
            this[7] = (uint8)Commands.LF;
        }

        public Message.STX ()
        {
            base (1);
            this[0] = (uint8)Commands.STX;
        }

        public Message.ETX ()
        {
            base (1);
            this[0] = (uint8)Commands.ETX;
        }

        public Message.EOT ()
        {
            base (1);
            this[0] = (uint8)Commands.EOT;
        }

        public Message.ENQ ()
        {
            base (1);
            this[0] = (uint8)Commands.ENQ;
        }

        public Message.ETB ()
        {
            base (1);
            this[0] = (uint8)Commands.ETB;
        }

        public Message.ACK ()
        {
            base (1);
            this[0] = (uint8)Commands.ACK;
        }

        public Message.NACK ()
        {
            base (1);
            this[0] = (uint8)Commands.NACK;
        }

        public Message.CR ()
        {
            base (1);
            this[0] = (uint8)Commands.CR;
        }

        public Message.LF ()
        {
            base (1);
            this[0] = (uint8)Commands.LF;
        }
    }
}
