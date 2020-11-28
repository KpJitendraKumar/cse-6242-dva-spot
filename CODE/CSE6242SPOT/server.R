function(input, output, session) {

  # reactive values ====================================================

  # to store the source location
  source_loc <- reactive({
    # If option selected to use the devide location
    if (input$use_current_as_src){
      return(list(lat = input$lat, lon = input$long))
    } else {
      t <- input$src_input_txt
      t <- as.numeric(unlist(strsplit(t, ",")))
      if (NA %in% t){
        a <- data.frame(geocode(input$src_input_txt, output = "latlona"))
        return(list(lat = a$lat, lon = a$lon))
      }
      return(list(lat = t[1], lon = t[2]))
    }
  })

  # To store the destination
  destination_loc <- reactive({
    t <- input$dest_input_txt
    t <- as.numeric(unlist(strsplit(t, ",")))
    if (NA %in% t){
      a <- data.frame(geocode(input$dest_input_txt, output = "latlona"))
      return(list(lat = a$lat, lon = a$lon))
    }
    return(list(lat = t[1], lon = t[2]))
  })

  # To store the path co-ordinates
  path <- reactiveValues(list = list(lat = NULL, lon = NULL))

  # Current location when travelling
  current_loc_travel <- reactiveValues(list = list(lat = 1, lon = 1))

  # Flag to indicate driver is travelling
  ontravel <- reactiveValues(status = FALSE)

  # Swithc tabs to dashboard
  observeEvent(input$close_load, {
    updateTabItems(session, "tabs", "dashboard")
  })

  # Find the path when button is pressed
  observeEvent(input$find_path_btn, {
    path_type <- "length"

    if (input$short_vs_safe == 1){
      path_type <- "accidents"
    } else if (input$short_vs_safe == 0.25){
      path_type <- "accidents_25"
    } else if (input$short_vs_safe == 0.5){
      path_type <- "accidents_50"
    } else if (input$short_vs_safe == 0.75){
      path_type <- "accidents_75"
    }

    if(is.null(source_loc()$lat) | is.null(source_loc()$lon) |
       is.na(source_loc()$lat) | is.na(source_loc()$lon)){
      shinyWidgets::sendSweetAlert(session, title = "Source Location Missing",
                                   text =  "Enter the source or allow location information to the app", type = "error")
    } else if (is.null(destination_loc()$lat) | is.null(destination_loc()$lon) |
                  is.na(destination_loc()$lat) | is.na(destination_loc()$lon)){
      shinyWidgets::sendSweetAlert(session, title = "Destination Location Missing",
                                   text =  "Enter the destination or allow location information to the app", type = "error")
    } else if (py_found == "error"){
      shinyWidgets::sendSweetAlert(session, title = "Python not found!",
                                   text =  'While running the app pass the python executable folder path.
                                   You can find the path using python3 -c "import sys; print(sys.executable)".
                                   For more information see https://stackoverflow.com/questions/749711/how-to-get-the-python-exe-location-programmatically
                                   Also ensure that all the python libraries re installed in the same python instance.',
                                   type = "error")
    } else {
      y_ <- get_path(c(source_loc()$lat, source_loc()$lon),
                     c(destination_loc()$lat, destination_loc()$lon),
                     path_type)
      lat <- y_[seq(1,length(y_),2)]
      lon <- y_[seq(2,length(y_),2)]
      path$list$lat <- lat
      path$list$lon <- lon
    }
  })

  observeEvent(input$start_journey, {
    cnt <<- 0
    ontravel$status <- TRUE
  })

  observeEvent(input$stop_journey, {
    ontravel$status <- F
  })

  # start journey ====================================
  # below loop is to simulate the travel, this can be easily
  # replaced by actual travel by updating the line 166-167.
  # Just replace path$list$lon[cnt] with input$long and
  # path$list$lat[cnt] with input$lat for this

  observe({
    if (ontravel$status){

      invalidateLater(3000)
      shinydashboard::updateTabItems(session, "start_journey", "journey")
      ontravel$status <- TRUE
      cnt <<- cnt+2

      accident_prob <- get_accident_risk(c(path$list$lat[cnt], path$list$lon[cnt]))
      print(accident_prob)

      if (accident_prob > 4e-08){ # cutoff probability for alert
        output$alert <- renderUI({
          img(src='accident.png', align = "right")
        })
        beepr::beep(5)
      } else {
        output$alert <- renderUI({
          tags$h3("Drive Safe!")
        })
      }

      output$path_plot <- plotly::renderPlotly({

        lat_ <- path$list$lat
        lon_ <- path$list$lon

        center_ <- c(mean(lat_), mean(lon_))


        plot_df <- data.frame(lat = lat_,
                              lon = lon_)

        source_ <- c(source_loc()$lat, source_loc()$lon)
        destination_ <- c(destination_loc()$lat, destination_loc()$lon)

        p <- plot_ly() %>%
          add_trace(
            name = "Path",
            type = 'scattermapbox',
            mode = "lines",
            lon = lon_,
            lat = lat_,
            hoverinfo = "none",
            line = list(width = 4.5, color = 'blue'))  %>%
          # For source location
          add_trace(
            type = 'scattermapbox',
            name = "Source",
            mode = "marker",
            lon = source_[2],
            lat = source_[1],
            showlegend = T,
            hovertemplate = paste('<b>Lat</b>:   %{lat:.2f}',
                                  '<br><b>Lon</b>: %{lon:.2f}<br>',
                                  '<extra></extra>'),
            marker = list(size = 10, color = 'green')) %>%
          # For Destination location
          add_trace(
            type = 'scattermapbox',
            name = "Destination",
            mode = "marker",
            lon = destination_[2],
            lat = destination_[1],
            hovertemplate = paste('<b>Lat</b>:   %{lat:.2f}',
                                  '<br><b>Lon</b>: %{lon:.2f}<br>',
                                  '<extra></extra>'),
            marker = list(size = 10, color = 'black')) %>%
          layout(
            mapbox = list(
              style = "stamen-terrain",
              center = list(lon = center_[2], lat= center_[1]),
              zoom = 12),
            margin =list(l=0,t=0,b=0,r=0))

        # For current location
        p <- p %>% add_trace(
          type = 'scattermapbox',
          name = "Current Location",
          mode = "marker",
          lon = path$list$lon[cnt],
          lat = path$list$lat[cnt],
          hovertemplate = paste('<b>Lat</b>:   %{lat:.2f}',
                                '<br><b>Lon</b>: %{lon:.2f}<br>',
                                '<extra></extra>'),
          marker = list(size = 10, color = 'red')) %>%
          layout(legend = list(orientation = 'h'))

        p %>% toWebGL()
      })
    }

  })

  # Initial plot to shoe the path
  output$path_plot <- plotly::renderPlotly({

    if(is.null(path$list$lat)){
      lat_ <- c(1)
      lon_ <- c(1)
      center_ <- c(33.779853, -84.384140)
    } else {
      lat_ <- path$list$lat
      lon_ <- path$list$lon
      center_ <- c(mean(lat_), mean(lon_))
    }

    # checking for NULL source location
    if (is.null(source_loc())){
      source_ <- c(1,1)
      src_show_legend <- F
    } else {
      source_ <- c(source_loc()$lat, source_loc()$lon)
      src_show_legend <- T
    }

    # checking for NULL destination location
    if (is.null(destination_loc())){
      destination_ <- c(1,1)
      dest_show_legend <- F
    } else {
      destination_ <- c(destination_loc()$lat, destination_loc()$lon)
      dest_show_legend <- T
    }

    curr_show_legend <- T

    p <- plot_ly() %>%
      add_trace(
        name = "Path",
        type = 'scattermapbox',
        mode = "lines",
        lon = lon_,
        lat = lat_,
        hoverinfo = "none",
        line = list(width = 4.5, color = 'blue'))  %>%
      # For source location
      add_trace(
        type = 'scattermapbox',
        name = "Source",
        mode = "marker",
        lon = source_[2],
        lat = source_[1],
        showlegend = curr_show_legend,
        hovertemplate = paste('<b>Lat</b>:   %{lat:.2f}',
                              '<br><b>Lon</b>: %{lon:.2f}<br>',
                              '<extra></extra>'),
        marker = list(size = 10, color = 'green')) %>%
      # For Destination location
      add_trace(
        type = 'scattermapbox',
        name = "Destination",
        mode = "marker",
        lon = destination_[2],
        lat = destination_[1],
        hovertemplate = paste('<b>Lat</b>:   %{lat:.2f}',
                              '<br><b>Lon</b>: %{lon:.2f}<br>',
                              '<extra></extra>'),
        marker = list(size = 10, color = 'black')) %>%

      layout(
        mapbox = list(
          style = "stamen-terrain",
          center = list(lon = center_[2], lat= center_[1]),
          zoom = 12),
        margin =list(l=0,t=0,b=0,r=0))

    curr <- c(input$lat, input$long)

    # For current location
    p <- p %>% add_trace(
      type = 'scattermapbox',
      name = "Current Location",
      mode = "marker",
      lon = curr[2],
      lat = curr[1],
      hovertemplate = paste('<b>Lat</b>:   %{lat:.2f}',
                            '<br><b>Lon</b>: %{lon:.2f}<br>',
                            '<extra></extra>'),
      marker = list(size = 10, color = 'red')) %>%
      layout(legend = list(orientation = 'h'))

    p %>% toWebGL()

  })

  # Showing current device location
  output$gps_loc <- renderPrint({
    if (is.null(input$lat)){
      return("Can't access device location")
    }
    return(paste(input$lat,", ", input$long))
  })

  # input widget for year
  output$select_year_ui <- renderUI({

    choices <- unique(us_data$Year)

    shinyWidgets::pickerInput(
      inputId = "year",
      label = "Select/deselect years",
      choices = choices,
      selected = "All",
      options = list(
        `actions-box` = TRUE,
        size = 10,
        `selected-text-format` = "count > 3"
      ),
      multiple = TRUE
    )
  })

  # Get the selcted year
  get_year <- reactive({
    if ("All" %in% input$year  | is.null(input$year)){
      return("All")
    } else {
      return(input$year)
    }
  })

  # Get the selected state
  get_state <- reactive({
    d <- event_data("plotly_click")
    if (is.null(d)) return("All") else state_abb[as.numeric(d[2])+1]
  })

  # chlorpleth map
  output$choropleth_map <- plotly::renderPlotly({

    us_filt <- us_data[us_data$Year %in% get_year(), ]
    us_filt <- data.frame(us_filt %>%
                              dplyr::group_by(State) %>%
                              summarise(NumOfAccidents = sum(NumOfAccidents)),
                            stringsAsFactors = F)

    us_filt$hover <- with(us_filt, paste('<b>',State,'</b>', '<br>', "Accidents:", NumOfAccidents))
    l <- list(color = toRGB("white"), width = 2)

    # specify some map projection/options
    g <- list(
      scope = 'usa',
      projection = list(type = 'albers usa'),
      showlakes = TRUE,
      lakecolor = toRGB('white')
    )

    p <- plot_geo(us_filt, locationmode = 'USA-states') %>%
      add_trace(
        z = ~NumOfAccidents, text = ~hover, locations = ~State,
        color = ~NumOfAccidents, colors = 'Purples'
      ) %>%
      colorbar(title = "Number of Accidents") %>%
      layout(
        title = 'Number of Accidents by State',
        geo = g
      )
    p
  })

  # line plot
  output$trend_plot <- plotly::renderPlotly({
    line_filt <- line_data[line_data$Year %in% input$year, ]

    plot_ly(line_filt, x = ~Month, y = ~Accidents, color = ~Year) %>%
      add_lines()
  })

  # bar plot
  output$week_plot <- plotly::renderPlotly({

    bar_filt <- bar_data[State %in% get_state()]
    bar_filt <- bar_filt[Year %in% get_year()]

    p <- plot_ly(bar_filt, x = ~Weekday, y = ~NumOfAccidents, type = 'bar', text = ~text,
                 frame = ~Month,
                 marker = list(color = 'rgb(158,202,225)',
                               line = list(color = 'rgb(8,48,107)',
                                           width = 1.5))) %>%
      layout(title = "Weekly Accidents",
             xaxis = list(title = ""),
             yaxis = list(title = ""))
    p

  })

  # heat map
  output$heat_map <- plotly::renderPlotly({
    accidents %>%
      plot_ly() %>%
      add_trace(
        type = 'densitymapbox',
        lat = ~Start_Lat,
        lon = ~Start_Lng,
        coloraxis = 'coloraxis',
        showlegend = T,
        radius = 2
      ) %>%
      layout(
        mapbox = list(
          style = "stamen-terrain",
          center = list(lon = -84.27, lat= 33),
          coloraxis = list(colorscale = "Viridis"),
          showlegend = F,
          zoom = 6),
        margin =list(l=0,t=0,b=0,r=0),
        showlegend = F)
  })
  # value boxes
  output$selected_state_vb <- shinydashboard::renderValueBox({
    valueBox(
      paste(get_state(), collapse = ", "), "Selected State", icon = icon("list"),
      color = "purple"
    )
  })

  output$selected_year_vb <- shinydashboard::renderValueBox({
    valueBox(
      paste(get_year(), collapse = ", "), "Selected Yeas(s)", icon = icon("calendar-alt"),
      color = "purple"
    )
  })

  output$selected_accidents_vb <- shinydashboard::renderValueBox({
    if ("All" %in% get_state()){
      return(valueBox(
        "-", "Select a state", icon = icon("car-crash"),
        color = "purple"
      ))
    }
    count <- us_data[us_data$Year %in% get_year(), ]
    count <- sum(count[count$State %in% get_state(), 3])
    valueBox(
      prettyNum(count, big.mark = ","),
      paste0("Accidents happened in state: ", get_state(), " in year: ", paste0(get_year(), collapse =", ")), icon = icon("car-crash"),
      color = "purple"
    )
  })

  # Adding source and destination input
  output$dest_input_txt_ui <- renderUI({
    textInput("dest_input_txt", label = h3("Destination"), value = "33.779853, -84.384140")
  })
  output$src_input_txt_ui <- renderUI({
    textInput("src_input_txt", label = h3("Source"), value = "The local on 14th")
  })
}
