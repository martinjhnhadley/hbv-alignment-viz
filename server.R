library("shiny")
library("tidyverse")
library("DT")
library("shinyjs")
# devtools::install_github("martinjhnhadley/gene.alignment.tables")
library("gene.alignment.tables")

source("data-processing.R", local = TRUE)

table_width <- 15

function(input, output, session) {
  
  alignment.dt.unique.id <- alignment_DT_unique_id()
  
  output$programmatic_many_DT_UI <- renderUI({

    the_datatables <- hbv_table_data %>%
      filter(sheet == input$selected_species) %>%
      select(-sheet, -african.data) %>%
      generate_dts(table.width = table_width,
                   alignment.table.id = alignment.dt.unique.id)

    fluidPage(
      the_datatables
    )
    
  })
  
  selected_col_values <- reactiveValues()
  
  observe({
    if (!is.null(input[[paste0(alignment.dt.unique.id,
                               "_1_",
                               table_width,
                               "_rows_current")]])) {
      selected_col_values[["previous"]] <-
        isolate(selected_col_values[["current"]])
      
      all_inputs <- isolate(reactiveValuesToList(input))
      
      inputs_selected_cols <-
        grepl(
          paste0(
            alignment.dt.unique.id,
            "_[0-9]{1,}_[0-9]{1,}_columns_selected"
          ),
          names(all_inputs)
        )
      
      inputs_with_nulls <- all_inputs[inputs_selected_cols]
      
      inputs_selected_cols <-
        setNames(inputs_with_nulls, names(all_inputs)[inputs_selected_cols])
      
      selected_positions <-
        lapply(names(inputs_selected_cols), function(id) {
          id_to_sequence_position(id, shiny.input = input)
        }) %>%
        unlist()
      
      selected_positions
      
      
    } else {
      if (is.null(selected_col_values[["current"]])){
        selected_positions <- NULL
      }
      else {
        selected_positions <- selected_col_values[["current"]]
      }
    }
    
    selected_col_values[["current"]] <- selected_positions
  })
  
  
  output$observe_show_inputs <- renderDataTable({
    selected_positions <- selected_col_values[["current"]] %>%
      sort()
    
    if (is.null(selected_positions)) {
      
      show("loading-content")
      
      hbv_table_data[0,] %>%
        datatable()
    } 
    
    hide("loading-content")
    
    hbv_table_data %>%
      filter(sheet == input$selected_species) %>%
      select(-sheet, -african.data) %>%
      filter(position %in% selected_positions) %>%
      datatable()
  })
  
  
  
}