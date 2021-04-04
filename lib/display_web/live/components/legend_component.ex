defmodule Legend do
  @moduledoc false
  use Surface.LiveComponent

  def render(assigns) do
    ~H"""
    <div class="legend">
      <div class="no-wheelchair"><svg xmlns="http://www.w3.org/2000/svg" width="42.989" height="42.989"
          viewBox="0 0 42.989 42.989">
          <g transform="translate(0 0)">
            <path
              d="M23.991,18.65l.688,1.386a.774.774,0,0,1-.349,1.037l-3.166,1.59a1.548,1.548,0,0,1-2.089-.728l-3.036-6.461H9.285a1.548,1.548,0,0,1-1.532-1.329C6.114,2.675,6.208,3.387,6.19,3.095A3.095,3.095,0,1,1,9.738,6.157l.226,1.581h6.285a.774.774,0,0,1,.774.774v1.547a.774.774,0,0,1-.774.774H10.406l.221,1.547h6.4a1.547,1.547,0,0,1,1.4.889L21.2,19.189l1.75-.887a.774.774,0,0,1,1.037.349Zm-8.934-1.628H13.872A5.416,5.416,0,1,1,5.819,11.55L5.36,8.342A8.511,8.511,0,1,0,16.3,19.673Z"
              transform="translate(10.201 8.324)" fill="#eee"></path>
            <g transform="translate(0 0)" fill="none" stroke="#eee" stroke-width="4">
              <circle cx="21.494" cy="21.494" r="21.494" stroke="none"></circle>
              <circle cx="21.494" cy="21.494" r="19.494" fill="none"></circle>
            </g>
            <path d="M-6200.484-9303.2l28.884,30.357" transform="translate(6207.76 9309.878)" fill="none" stroke="#eee"
              stroke-width="4"></path>
          </g>
        </svg>
        <p>Wheelchair <br>Not Accessible</p>
      </div>
      <div class="seat-available seats"><span class="indicator"></span>
        <p>Seat<br>Available</p>
      </div>
      <div class="standing-available seats"><span class="indicator"></span>
        <p>Standing<br>Available</p>
      </div>
      <div class="limited-standing seats"><span class="indicator"></span>
        <p>Limited<br>Standing</p>
      </div>
    </div>
    """
  end
end
