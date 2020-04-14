defmodule PokerXWeb.LobbyComponent do
  use Phoenix.LiveComponent

  def render(assigns) do
    ~L"""
    <div class="bg-white shadow overflow-hidden sm:rounded-md">
    <ul>
    <%= for table <- @tables do %>
    <li>
      <a href="#" class="block hover:bg-gray-50 focus:outline-none focus:bg-gray-50 transition duration-150 ease-in-out">
        <div class="px-4 py-4 flex items-center sm:px-6">
          <div class="min-w-0 flex-1 sm:flex sm:items-center sm:justify-between">
            <div>
              <div class="text-sm leading-5 font-medium text-indigo-600 truncate">
                Back End Developer
                <span class="ml-1 font-normal text-gray-500">
                  in Engineering
                </span>
              </div>
              <div class="mt-2 flex">
                <div class="flex items-center text-sm leading-5 text-gray-500">
                  <svg class="flex-shrink-0 mr-1.5 h-5 w-5 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
                    <path fill-rule="evenodd" d="M6 2a1 1 0 00-1 1v1H4a2 2 0 00-2 2v10a2 2 0 002 2h12a2 2 0 002-2V6a2 2 0 00-2-2h-1V3a1 1 0 10-2 0v1H7V3a1 1 0 00-1-1zm0 5a1 1 0 000 2h8a1 1 0 100-2H6z" clip-rule="evenodd"/>
                  </svg>
                  <span>
                    Closing on
                    <time datetime="2020-01-07">January 7, 2020</time>
                  </span>
                </div>
              </div>
            </div>
            <div class="mt-4 flex-shrink-0 sm:mt-0">
              <div class="flex overflow-hidden">
                <img class="inline-block h-6 w-6 rounded-full text-white shadow-solid" src="https://images.unsplash.com/photo-1491528323818-fdd1faba62cc?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="" />
                <img class="-ml-1 inline-block h-6 w-6 rounded-full text-white shadow-solid" src="https://images.unsplash.com/photo-1550525811-e5869dd03032?ixlib=rb-1.2.1&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="" />
                <img class="-ml-1 inline-block h-6 w-6 rounded-full text-white shadow-solid" src="https://images.unsplash.com/photo-1500648767791-00dcc994a43e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2.25&w=256&h=256&q=80" alt="" />
                <img class="-ml-1 inline-block h-6 w-6 rounded-full text-white shadow-solid" src="https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?ixlib=rb-1.2.1&ixid=eyJhcHBfaWQiOjEyMDd9&auto=format&fit=facearea&facepad=2&w=256&h=256&q=80" alt="" />
              </div>
            </div>
          </div>
          <div class="ml-5 flex-shrink-0">
            <svg class="h-5 w-5 text-gray-400" fill="currentColor" viewBox="0 0 20 20">
              <path fill-rule="evenodd" d="M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z" clip-rule="evenodd"/>
            </svg>
          </div>
        </div>
      </a>
    </li>
    <% end %>
    </ul>
    </div>
    """
  end

  def mount(socket) do
    socket = assign(socket, tables: [])
    {:ok, socket}
  end

  def update(assigns, socket) do
    {:ok, socket}
  end
end
