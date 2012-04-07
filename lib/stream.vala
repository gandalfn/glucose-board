/* -*- Mode: Vala; indent-tabs-mode: nil; c-basic-offset: 4; tab-width: 4 -*- */
/*
 * stream.vala
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
    public errordomain StreamError
    {
        OK,
        NOT_INITIALIZED,
        INVALID_DEVICE,
        OPEN_DEVICE,
        CLOSE_DEVICE,
        NOT_OPENED,
        ALREADY_OPEN,
        RECEIVED_THREAD,
        RECEIVED_TIMEOUT,
        READ,
        WRITE
    }

    /**
     * This class provides some basic functionality, which can be used by all other communication classes.
     */
    public abstract class Stream : GLib.Object
    {
        // type
        public delegate void ReceivedCallback (Stream inStream);

        private class ReadRequest : GLib.Object
        {
            public Message                   m_Message;
            public uint                      m_Timeout;
            public StreamError               m_Status;
            public unowned ReceivedCallback? m_Callback;

            public ReadRequest (Message inMessage, uint inTimeout, ReceivedCallback? inCallback)
            {
                m_Message = inMessage;
                m_Timeout = inTimeout;
                m_Status = new StreamError.OK ("");
                m_Callback = inCallback;
            }

            public ReadRequest.end ()
            {
                m_Message = null;
                m_Timeout = 0;
            }
        }

        // properties
        private bool                           m_IsOpened = false;
        private GLib.AsyncQueue<ReadRequest>   m_PendingReceiveQueue;
        private GLib.AsyncQueue<ReadRequest>   m_ReceiveQueue;
        private unowned GLib.Thread<void*>?    m_ReceiveThreadId;

        // accessors
        /**
         * if ``true``, if stream is open.
         */
        public bool is_open {
            get {
                return m_IsOpened;
            }
        }

        /**
         * The number of stored messages in the queue
         */
        public uint length {
            get {
                return m_ReceiveQueue.length ();
            }
        }

        // signals
        /**
         * This signal is emitted if there is a message was received.
         */
        public signal void received ();

        /**
         * This signal is emitted, when stream device is open
         */
        public signal void opened ();

        /**
         * This signal is emitted, when stream device closed
         */
        public signal void closed ();

        // methods
        /**
         * Create a new Stream. This is the only time, when the use_queue can be set.
         */
        public Stream ()
        {
            m_ReceiveQueue        = new GLib.AsyncQueue<ReadRequest> ();
            m_PendingReceiveQueue = new GLib.AsyncQueue<ReadRequest> ();
        }

        ~Stream ()
        {
            GlucoseBoard.Log.debug ("Destroy stream");
            if (m_IsOpened) close ();
        }

        private void
        start_receive_thread () throws StreamError
        {
            // Start read thread
            if (m_ReceiveThreadId == null)
            {
                try
                {
                    m_ReceiveThreadId = GLib.Thread.create<void*> (() => {
                        while (m_IsOpened)
                        {
                            ReadRequest request = m_PendingReceiveQueue.pop ();
                            if (request != null && request.m_Message != null)
                            {
                                try
                                {
                                    read (ref request.m_Message, request.m_Timeout);
                                }
                                catch (StreamError err)
                                {
                                    request.m_Status = err;
                                }

                                m_ReceiveQueue.push (request);

                                SourceFunc func = () => {
                                    if (request.m_Callback != null) request.m_Callback (this);
                                    received ();
                                    return false;
                                };

                                GLib.Idle.add ((owned)func);
                            }
                        }

                        return null;
                    }, true);
                }
                catch (GLib.ThreadError err)
                {
                    throw new StreamError.RECEIVED_THREAD ("%s", err.message);
                }
            }
        }

        /**
         * Should be called by the derived class, when the device stream is open
         *
         * @throws StreamError throw when something goes wrong
         */
        protected void
        on_opened () throws StreamError
        {
            if (m_IsOpened == true)
                throw new StreamError.ALREADY_OPEN ("The stream is already open");

            m_IsOpened = true;

            opened ();

            Log.debug ("Opened");
        }

        /**
         * Should be called by the derived class, when the device stream was closed
         */
        protected void
        on_closed ()
        {
            bool raiseEvent = true;
            if (m_IsOpened == false)
                raiseEvent = false;

            m_IsOpened = false;

            // Wait for read thread terminaison
            if (m_ReceiveThreadId != null)
            {
                m_PendingReceiveQueue.push (new ReadRequest.end ());
                m_ReceiveThreadId.join ();
                m_ReceiveThreadId = null;
            }

            // Flush queues
            flush_queue ();

            if (raiseEvent)
                closed ();

            Log.debug ("Closed");
        }

        /**
         * Function returns a new message via the message variable.
         *
         * @param outMessage The new message.
         * @param inTimeout The waiting time for the new message in milliseconds.
         *
         * @throws StreamError raise when something went wrong
         */
        protected abstract void read (ref Message outMessage, uint inTimeout) throws StreamError;

        /**
         * This function must be called in order to open stream device.
         *
         * @throws StreamError raise when something went wrong
         */
        public abstract void open () throws StreamError;

        /**
         * This function must be called in order to close the stream device.
         *
         * @throws StreamError raise when something went wrong
         */
        public abstract void close () throws StreamError;

        /**
         * Send a message via the used interface.
         *
         * @param inMessage The message
         * @param inTimeout The waiting time for writing new message in milliseconds.
         *
         * @throws StreamError raise when something went wrong
         */
        public abstract void send (Message inMessage, uint inTimeout) throws StreamError;

        /**
         * Function launch async read request, stream emit received signal when received
         * is processed
         *
         * @param inMessage The new message.
         * @param inTimeout The waiting time for the new message in milliseconds.
         */
        public void recv (Message inMessage, uint inTimeout, ReceivedCallback? inCallback = null) throws StreamError
        {
            ReadRequest request = new ReadRequest (inMessage, inTimeout, inCallback);
            m_PendingReceiveQueue.push (request);
            start_receive_thread ();
        }

        /**
         * Get message in read queue block until a new read message is not received
         */
        public Message
        pop () throws StreamError
        {
            Message msg = null;
            ReadRequest? request = m_ReceiveQueue.pop ();
            if (request != null)
            {
                if (!(request.m_Status is StreamError.OK))
                    throw request.m_Status;
                msg = (owned)request.m_Message;
            }
            else
            {
                throw new StreamError.READ ("Error on get last read message");
            }

            return msg;
        }

        /**
         * Deletes all the elements, that are currently stored in the queue.
         */
        public void
        flush_queue ()
        {
            while (m_PendingReceiveQueue.try_pop () != null);
            while (m_ReceiveQueue.try_pop () != null);
        }
    }
}
