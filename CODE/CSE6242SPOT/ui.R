dashboardPage(
  dashboardHeader(title = "SPOT"),
  dashboardSidebar(
    sidebarMenu(
      id = "tabs",
      menuItem("Home", tabName = "home"),
      menuItem("Dashboard", tabName = "dashboard"),
      menuItem("Find Safest Path", tabName = "safestpath")
    )
  ),
  dashboardBody(

    # changing theme
    shinyDashboardThemes(
      theme = "boe_website"
    ),
    useShinyjs(),

    # Script to get the current location -------------------------
    tags$script('
      $(document).ready(function () {
        navigator.geolocation.getCurrentPosition(onSuccess, onError);

        function onError (err) {
          Shiny.onInputChange("geolocation", false);
        }

        function onSuccess (position) {
          setTimeout(function () {
            var coords = position.coords;
            console.log(coords.latitude + ", " + coords.longitude);
            Shiny.onInputChange("geolocation", true);
            Shiny.onInputChange("lat", coords.latitude);
            Shiny.onInputChange("long", coords.longitude);
          }, 1100)
        }
      });
              '),
    tabItems(

      tabItem(
        tabName = "home",
        tags$div(id = "homepage", style = "position: fixed; height: 100%; width: 100%; top: 0; left: 0;
               background: #ECF0F5;z-index: 8700; background-image: url('road.png');background-size: cover;",
                 tags$img(src = "poster_logo.png", style = "height: 17%; width: 30%;margin-top: 0.2%;"), #padding-right:2%; float:right;
                 div(class="btn-HOmePage",
                     actionButton("close_load", label = "Proceed", icon=icon('forward'),
                                  style = "margin-right: 10%; background-color :#565654;
                               font-size: 130%; margin-top: 33.5%;float:right;border:0;height:7%;width:10%;")
                 )
        )
      ),
      tabItem("dashboard",
              fluidRow(
                column(6, shiny::uiOutput("select_year_ui")),
                column(6, fluidRow(tags$blockquote("Please a wait till the density map loads completely.")),
                       fluidRow(tags$blockquote("If any plot is not fully covering its box, please resize and maximize the window.")))
              ),
              fluidRow(
                box(column(12,height = '350px',
                           fluidRow(plotly::plotlyOutput("choropleth_map", height = '300px'))),
                    status = "primary"
                    ),
                box(column(12, height = '350px',plotly::plotlyOutput("heat_map",height = '300px')),
                    status = "primary")
              ),
              fluidRow(
                shinydashboard::valueBoxOutput("selected_year_vb"),
                shinydashboard::valueBoxOutput("selected_state_vb"),
                shinydashboard::valueBoxOutput("selected_accidents_vb")
              ),
              fluidRow(
                box(column(12, height = '300px',
                           fluidRow(plotly::plotlyOutput("trend_plot", height = '250px'))),
                    status = "primary"),
                box(column(12, height = '300px',
                           fluidRow(plotly::plotlyOutput("week_plot", height = '250px'))),
                    status = "primary")
              )

      ),
      tabItem("safestpath",
              box(width = 8, plotly::plotlyOutput("path_plot", height = "750px"), height = '800px'),
              box(width = 4,
                  uiOutput("src_input_txt_ui"),
                  switchInput("use_current_as_src", "Source?", value = F, onLabel = "Using device location",
                              offLabel = "Using source input"),
                  uiOutput("dest_input_txt_ui"),
                  sliderInput("short_vs_safe", label = h3("Safety weight"), min = 0,
                              max = 1, value = 1, step = 0.25),
                  actionButton("find_path_btn", "Find Path"),
                  actionButton("start_journey", "Start"),
                  actionButton("stop_journey", "Stop"),
                  tags$h3("Your location"),
                  verbatimTextOutput("gps_loc"),
                  uiOutput("alert")

              )
      )
    )
  )
)
