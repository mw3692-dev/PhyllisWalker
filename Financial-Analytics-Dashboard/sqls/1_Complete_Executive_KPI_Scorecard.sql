SELECT
   -- ==========================================
   -- SECTION 1 & 2 & 3: MONTHLY TRENDS (Totals, Cleared, Pending)
   -- ==========================================
   -- Current Month to Date (Aug 2026)
   SUM(CASE WHEN STRFTIME('%Y-%m', "Invoice date") = STRFTIME('%Y-%m', 'now')
       THEN "Amount billed" ELSE 0 END) AS Total_Current_MTD,    
   SUM(CASE WHEN STRFTIME('%Y-%m', "Invoice date") = STRFTIME('%Y-%m', 'now') AND "Invoice status" = 'Paid'
       THEN "Amount billed" ELSE 0 END) AS Cleared_Current_MTD,    
   SUM(CASE WHEN STRFTIME('%Y-%m', "Invoice date") = STRFTIME('%Y-%m', 'now') AND "Invoice status" = 'Open'
       THEN "Amount billed" ELSE 0 END) AS Pending_Current_MTD,
   -- Last Month (Jul 2026)
   SUM(CASE WHEN STRFTIME('%Y-%m', "Invoice date") = STRFTIME('%Y-%m', 'now', '-1 month')
       THEN "Amount billed" ELSE 0 END) AS Total_Last_Month,   
   SUM(CASE WHEN STRFTIME('%Y-%m', "Invoice date") = STRFTIME('%Y-%m', 'now', '-1 month') AND "Invoice status" = 'Paid'
       THEN "Amount billed" ELSE 0 END) AS Cleared_Last_Month,     
   SUM(CASE WHEN STRFTIME('%Y-%m', "Invoice date") = STRFTIME('%Y-%m', 'now', '-1 month') AND "Invoice status" = 'Open'
       THEN "Amount billed" ELSE 0 END) AS Pending_Last_Month,
   -- Last-to-Last Month (Jun 2026)
   SUM(CASE WHEN STRFTIME('%Y-%m', "Invoice date") = STRFTIME('%Y-%m', 'now', '-2 months')
       THEN "Amount billed" ELSE 0 END) AS Total_L2L_Month,      
   SUM(CASE WHEN STRFTIME('%Y-%m', "Invoice date") = STRFTIME('%Y-%m', 'now', '-2 months') AND "Invoice status" = 'Paid'
       THEN "Amount billed" ELSE 0 END) AS Cleared_L2L_Month,     
   SUM(CASE WHEN STRFTIME('%Y-%m', "Invoice date") = STRFTIME('%Y-%m', 'now', '-2 months') AND "Invoice status" = 'Open'
       THEN "Amount billed" ELSE 0 END) AS Pending_L2L_Month,
   -- ==========================================
   -- SECTION 4: YEARLY MACRO PERFORMANCE
   -- ========================================== 
   -- Current Year to Date (CYTD)
   SUM(CASE WHEN STRFTIME('%Y', "Invoice date") = STRFTIME('%Y', 'now')
             AND DATE("Invoice date") <= DATE('now')
       THEN "Amount billed" ELSE 0 END) AS Total_CYTD,
   -- Last Year Total (LY)
   SUM(CASE WHEN STRFTIME('%Y', "Invoice date") = STRFTIME('%Y', 'now', '-1 year')
       THEN "Amount billed" ELSE 0 END) AS Total_LY,
   -- Last Year to Date (LYTD)
   SUM(CASE WHEN STRFTIME('%Y', "Invoice date") = STRFTIME('%Y', 'now', '-1 year')
             AND DATE("Invoice date") <= DATE('now', '-1 year')
       THEN "Amount billed" ELSE 0 END) AS Total_LYTD
FROM Invoices
WHERE "Invoice status" != 'Voided'
 AND "Invoice date" <> 'NULL';
