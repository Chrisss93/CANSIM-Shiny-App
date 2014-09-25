### [BEGIN] Conditional package installation and sourcing
required_packages <- c("shiny", "ggplot2", "scales", "plyr", "reshape2", "devtools", "shinyIncubator")
uninstalled_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if(length(uninstalled_packages) > 0) {
  install.packages(uninstalled_packages[!uninstalled_packages == "shinyIncubator"])
  install_github("shiny-incubator", "rstudio")
}
lapply(required_packages, require, character.only = TRUE)

### [BEGIN] Retrieving Data
fileUrl <- "http://www20.statcan.gc.ca/tables-tableaux/cansim/csv/02020802-eng.zip"
temp <- tempfile()

### [BEGIN] Minor data cleaning (cleaning is consistent with 24-09-2014 version of data)
small_cleaning <- function(base){
  base <- base[,c("Ref_Date", "GEOGRAPHY", "CUTOFFBASE", "STATISTICS", "LICOPERSONS", "Value")]
  colnames(base) <- c("Year", "Geography", "Line", "Statistic", "Population", "Value")
  base$Population <- factor(gsub(" \\(x 1,000\\)", "", base$Population))
  base$Statistic <- as.character(base$Statistic)
  base$Statistic[base$Statistic == "Number of persons in low income"] <- paste(base$Statistic[base$Statistic == "Number of persons in low income"], "(x 1,000)")
  base$Statistic <- factor(base$Statistic)
  base$Value <- suppressWarnings(as.numeric(as.character(base$Value)))
  return(base)
}

### [BEGIN] Defining useful constants
# Express general ggplot preset layers to be used (only options that do not have reactive elements)
gg_layers <- list(geom_line(), 
                  geom_point(), 
                  ylab("Poverty Rate"),
                  theme(legend.direction = "vertical", 
                        legend.position = "top", 
                        axis.text.x = element_text(angle = 45)))
# Too much junk/information in the dataset, create constant strings to denote parameters of interest
keep_population <- c("All persons", "Males", "Females", "Persons under 18 years", "Persons 18 to 64 years",
                     "Persons 65 years aand over", "Males, under 18 years", "Females, under 18 years",
                     "Males, 18 to 64 years", "Females, 18 to 64 years", "Males, 65 years and over",
                     "Females, 65 years and over")
keep_geography <- c("Canada", "Atlantic provinces","Newfoundland and Labrador", 
                    "Prince Edward Island", "Nova Scotia", "New Brunswick", 
                    "Quebec", "Ontario", "Prairie provinces","Manitoba", 
                    "Saskatchewan", "Alberta", "British Columbia")

### [BEGIN] Shiny reactive programming
shinyServer(function(input, output, session) {
  
  scrape_data <- reactive({
    withProgress(session, min = 1, max = 30, {
      setProgress(message = "Please wait while we retrieve the most current data from Statistics Canada.")
      for(i in 1:30) {setProgress(value = i)}
      download.file(fileUrl, temp)
      base <- read.csv(unz(temp, "02020802-eng.csv"))
      base <- small_cleaning(base)
      unlink(temp)
      base
    })
  })
  

  line_select <- reactive({
    base <- scrape_data()
    base[base$Line %in% input$line, ]
  })

  pop_select <- reactive({
    base2 <- line_select()

    keep_all <- paste(input$pop, input$pop2)
    #Dumb code below. I'll shore it up later.
    keep_all <- suppressMessages(revalue(keep_all,
                                         c("All All" = keep_population[1],
                                           "Male All" = keep_population[2],
                                           "Female All" = keep_population[3],
                                           "All Children" = keep_population[4],
                                           "All Adults" = keep_population[5],
                                           "All Elderly" = keep_population[6],
                                           "Male Children" = keep_population[7],
                                           "Female Children" = keep_population[8],
                                           "Male Adults" = keep_population[9],
                                           "Female Adults" = keep_population[10],
                                           "Male Elderly" = keep_population[11],
                                           "Female Elderly" = keep_population[12])))
    base2[base2$Population %in% keep_all, ]
  })

  geo_select <- reactive({
    base2 <- pop_select()
    base2[base2$Geography %in% input$geo, ]
  })

  output$plot1 <- renderPlot({
    df <- geo_select()
    df <- df[df$Statistic=="Percentage of persons in low income", ]
    gg_statement <- ggplot(df, aes(x = Year, y = Value / 100, color = Line, group = Line))
    gg_statement + gg_layers +
      ggtitle(paste(input$pop, input$pop2, input$geo, sep = "-")) +
      scale_x_continuous(breaks = seq(min(df$Year, na.rm = TRUE), max(df$Year, na.rm = TRUE), 5)) + 
      scale_y_continuous(breaks = seq(0, max(df$Value, na.rm=TRUE), 0.02), labels = percent) + 
      coord_cartesian(xlim = input$range)
  })
  
  output$plot2 <- renderPlot({
    df <- geo_select()
    df <- df[df$Statistic=="Number of persons in low income (x 1,000)", ]
    gg_statement <- ggplot(df, aes(x = Year, y = Value, color = Line, group = Line))
    gg_statement + gg_layers + ylab("Poverty count (x 1,000)") + 
      ggtitle(paste(input$pop, input$pop2, input$geo, sep = "-")) + 
      scale_x_continuous(breaks = seq(min(df$Year, na.rm = TRUE), max(df$Year, na.rm = TRUE), 5)) + 
      scale_y_continuous(labels = comma) + coord_cartesian(xlim = input$range)
  })
  # I'm making the table in a reactive({}) rather than renderTable({}) function, because I want write.csv()
  # functionality for the table, and that cannot be done on the output object directly.
  make_table <- reactive({
    base <- scrape_data()
    df <- base[base$Statistic %in% input$stat & 
                 base$Geography %in% keep_geography & 
                 base$Population %in% keep_population, ]
    tab <- dcast(df, df[, input$var1] ~ df[, input$var2], value.var = "Value", function(x){mean(x, na.rm=T)})
    colnames(tab)[1] <- names(df[input$var1])
    if(unique(df$Statistic) == "Percentage of persons in low income") {
      tab <- data.frame(tab[1], apply(tab[,-1], 2, function(x) {
        out <- percent(x/100)
        if (any(out == "NaN%") == TRUE) {
          out[out == "NaN%"] <- NA }
        return(out)
      }), check.names = FALSE)
      }
    tab
    })
  output$table <- renderTable({
    make_table()
  })
  
  output$downloadRaw <- downloadHandler(
    filename = function() { 
      paste("CANSIM ",Sys.Date(), ".csv", sep = "") 
    },
    content = function(file) {
      write.csv(base, file)
    }
  )
  output$downloadSummary <- downloadHandler(
    filename = function() { 
      paste(paste("CANSIM", input$stat, input$var1, input$var2, "Summary "), Sys.Date(), ".csv", sep = "") 
    },
    content = function(file) {
      write.csv(make_table(), file)
    }
  )
})