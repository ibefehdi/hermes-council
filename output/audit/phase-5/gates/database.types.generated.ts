Connecting to 127.0.0.1 54322
Generated TypeScript is unformatted. Format it with:
  npx oxfmt <generated-file.ts>

export type Json = string | number | boolean | null | { [key: string]: Json | undefined } | Json[]

export type Database = {
  
  "graphql_public": {
          Tables: {
            [_ in never]: never
          }
          Views: {
            [_ in never]: never
          }
          Functions: {
            "graphql":
{ Args: { "extensions"?: Json,"operationName"?: string,"query"?: string,"variables"?: Json }; Returns: Json
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        },"public": {
          Tables: {
            "appointment_items": {
                  Row: {
                    "appointment_id": string,"branch_id": string,"buffer_after_minutes": number,"buffer_before_minutes": number,"busy_range": unknown,"created_at": string,"created_by": string | null,"duration_minutes": number,"effective_end": string,"effective_start": string,"id": string,"price_minor": number,"service_id": string,"service_name_ar": string | null,"service_name_en": string | null,"sort_order": number,"staff_id": string | null,"status_active": boolean,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "appointment_id": string,"branch_id": string,"buffer_after_minutes"?: number,"buffer_before_minutes"?: number,"busy_range"?: unknown,"created_at"?: string,"created_by"?: string | null,"duration_minutes": number,"effective_end": string,"effective_start": string,"id"?: string,"price_minor": number,"service_id": string,"service_name_ar"?: string | null,"service_name_en"?: string | null,"sort_order"?: number,"staff_id"?: string | null,"status_active"?: boolean,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "appointment_id"?: string,"branch_id"?: string,"buffer_after_minutes"?: number,"buffer_before_minutes"?: number,"busy_range"?: unknown,"created_at"?: string,"created_by"?: string | null,"duration_minutes"?: number,"effective_end"?: string,"effective_start"?: string,"id"?: string,"price_minor"?: number,"service_id"?: string,"service_name_ar"?: string | null,"service_name_en"?: string | null,"sort_order"?: number,"staff_id"?: string | null,"status_active"?: boolean,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "appointment_items_appointment_branch_fk"
      columns: ["appointment_id","branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "appointments"
      referencedColumns: ["id","branch_id","tenant_id"]
    },{
      foreignKeyName: "appointment_items_appointment_id_tenant_id_fkey"
      columns: ["appointment_id","tenant_id"]
isOneToOne: false
      referencedRelation: "appointments"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "appointment_items_branch_fk"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "appointment_items_service_fk"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_effective_values"
      referencedColumns: ["service_id","tenant_id"]
    },{
      foreignKeyName: "appointment_items_service_fk"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "services"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "appointment_items_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "appointment_items_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"appointments": {
                  Row: {
                    "branch_id": string,"cancellation_note": string | null,"cancellation_reason_id": string | null,"cancelled_at": string | null,"cancelled_by": string | null,"client_id": string | null,"created_at": string,"created_by": string | null,"id": string,"notes": string | null,"ref_number": string,"scheduled_end": string,"scheduled_start": string,"status": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "branch_id": string,"cancellation_note"?: string | null,"cancellation_reason_id"?: string | null,"cancelled_at"?: string | null,"cancelled_by"?: string | null,"client_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"notes"?: string | null,"ref_number": string,"scheduled_end": string,"scheduled_start": string,"status"?: string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "branch_id"?: string,"cancellation_note"?: string | null,"cancellation_reason_id"?: string | null,"cancelled_at"?: string | null,"cancelled_by"?: string | null,"client_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"notes"?: string | null,"ref_number"?: string,"scheduled_end"?: string,"scheduled_start"?: string,"status"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "appointments_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "appointments_cancellation_reason_fk"
      columns: ["cancellation_reason_id","tenant_id"]
isOneToOne: false
      referencedRelation: "cancellation_reasons"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "appointments_client_fk"
      columns: ["client_id","tenant_id"]
isOneToOne: false
      referencedRelation: "clients"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "appointments_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"audit_log": {
                  Row: {
                    "action": string,"actor_id": string | null,"branch_id": string | null,"changed_fields": NonNullable<Json>,"created_at": string,"entity_id": string | null,"entity_type": string,"id": number,"tenant_id": string
                  }
                  Insert: {
                    "action": string,"actor_id"?: string | null,"branch_id"?: string | null,"changed_fields"?: NonNullable<Json>,"created_at"?: string,"entity_id"?: string | null,"entity_type": string,"id"?: never,"tenant_id": string
                  }
                  Update: {
                    "action"?: string,"actor_id"?: string | null,"branch_id"?: string | null,"changed_fields"?: NonNullable<Json>,"created_at"?: string,"entity_id"?: string | null,"entity_type"?: string,"id"?: never,"tenant_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "audit_log_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "audit_log_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"blocked_time_types": {
                  Row: {
                    "color": string,"created_at": string,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string | null,"sort_order": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "color"?: string,"created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "color"?: string,"created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "blocked_time_types_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"blocked_times": {
                  Row: {
                    "all_branches": boolean,"blocked_range": unknown,"blocked_time_type_id": string,"branch_id": string | null,"created_at": string,"created_by": string | null,"ends_at": string,"id": string,"notes": string | null,"staff_id": string,"starts_at": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "all_branches"?: boolean,"blocked_range"?: never,"blocked_time_type_id": string,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"ends_at": string,"id"?: string,"notes"?: string | null,"staff_id": string,"starts_at": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "all_branches"?: boolean,"blocked_range"?: never,"blocked_time_type_id"?: string,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"ends_at"?: string,"id"?: string,"notes"?: string | null,"staff_id"?: string,"starts_at"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "blocked_times_blocked_time_type_id_tenant_id_fkey"
      columns: ["blocked_time_type_id","tenant_id"]
isOneToOne: false
      referencedRelation: "blocked_time_types"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "blocked_times_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "blocked_times_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "blocked_times_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"booking_overrides": {
                  Row: {
                    "action": string,"appointment_id": string,"appointment_item_id": string | null,"branch_id": string,"created_at": string,"created_by": string,"details": NonNullable<Json>,"id": string,"reason": string | null,"rule": string,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "action": string,"appointment_id": string,"appointment_item_id"?: string | null,"branch_id": string,"created_at"?: string,"created_by": string,"details"?: NonNullable<Json>,"id"?: string,"reason"?: string | null,"rule": string,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "action"?: string,"appointment_id"?: string,"appointment_item_id"?: string | null,"branch_id"?: string,"created_at"?: string,"created_by"?: string,"details"?: NonNullable<Json>,"id"?: string,"reason"?: string | null,"rule"?: string,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "booking_overrides_appointment_id_tenant_id_fkey"
      columns: ["appointment_id","tenant_id"]
isOneToOne: false
      referencedRelation: "appointments"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "booking_overrides_appointment_item_id_tenant_id_fkey"
      columns: ["appointment_item_id","tenant_id"]
isOneToOne: false
      referencedRelation: "appointment_items"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "booking_overrides_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "booking_overrides_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"branch_opening_hours": {
                  Row: {
                    "branch_id": string,"closes_at": string,"created_at": string,"day_of_week": number,"id": string,"is_closed": boolean,"opens_at": string,"seq": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "branch_id": string,"closes_at": string,"created_at"?: string,"day_of_week": number,"id"?: string,"is_closed"?: boolean,"opens_at": string,"seq"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "branch_id"?: string,"closes_at"?: string,"created_at"?: string,"day_of_week"?: number,"id"?: string,"is_closed"?: boolean,"opens_at"?: string,"seq"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "branch_opening_hours_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    }
                  ]
                },"branches": {
                  Row: {
                    "address": string | null,"created_at": string,"enabled_payment_methods": (string)[],"first_day_of_week": number,"id": string,"invoice_prefix": string,"is_active": boolean,"name_ar": string | null,"name_en": string,"phone": string | null,"receipt_footer_ar": string | null,"receipt_footer_en": string | null,"receipt_header_ar": string | null,"receipt_header_en": string | null,"slot_step_minutes": number,"tenant_id": string,"time_format": number,"timezone": string,"tip_presets_percent": (number)[],"tips_enabled": boolean,"updated_at": string
                  }
                  Insert: {
                    "address"?: string | null,"created_at"?: string,"enabled_payment_methods"?: (string)[],"first_day_of_week"?: number,"id"?: string,"invoice_prefix"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en": string,"phone"?: string | null,"receipt_footer_ar"?: string | null,"receipt_footer_en"?: string | null,"receipt_header_ar"?: string | null,"receipt_header_en"?: string | null,"slot_step_minutes"?: number,"tenant_id": string,"time_format"?: number,"timezone"?: string,"tip_presets_percent"?: (number)[],"tips_enabled"?: boolean,"updated_at"?: string
                  }
                  Update: {
                    "address"?: string | null,"created_at"?: string,"enabled_payment_methods"?: (string)[],"first_day_of_week"?: number,"id"?: string,"invoice_prefix"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string,"phone"?: string | null,"receipt_footer_ar"?: string | null,"receipt_footer_en"?: string | null,"receipt_header_ar"?: string | null,"receipt_header_en"?: string | null,"slot_step_minutes"?: number,"tenant_id"?: string,"time_format"?: number,"timezone"?: string,"tip_presets_percent"?: (number)[],"tips_enabled"?: boolean,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "branches_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"cancellation_reasons": {
                  Row: {
                    "created_at": string,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string | null,"sort_order": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "created_at"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "cancellation_reasons_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"client_import_batches": {
                  Row: {
                    "batch_key": string,"chunk_count": number,"chunks_done": number,"completed_at": string | null,"created_at": string,"created_by": string | null,"duplicate_policy": string,"failed_count": number,"file_name": string | null,"id": string,"imported_count": number,"invalid_count": number,"marked_count": number,"skipped_count": number,"status": string,"tenant_id": string,"total_rows": number,"updated_at": string,"updated_by": string | null,"client_import_batch_summary": Json | null
                  }
                  Insert: {
                    "batch_key": string,"chunk_count"?: number,"chunks_done"?: number,"completed_at"?: string | null,"created_at"?: string,"created_by"?: string | null,"duplicate_policy": string,"failed_count"?: number,"file_name"?: string | null,"id"?: string,"imported_count"?: number,"invalid_count"?: number,"marked_count"?: number,"skipped_count"?: number,"status"?: string,"tenant_id": string,"total_rows": number,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "batch_key"?: string,"chunk_count"?: number,"chunks_done"?: number,"completed_at"?: string | null,"created_at"?: string,"created_by"?: string | null,"duplicate_policy"?: string,"failed_count"?: number,"file_name"?: string | null,"id"?: string,"imported_count"?: number,"invalid_count"?: number,"marked_count"?: number,"skipped_count"?: number,"status"?: string,"tenant_id"?: string,"total_rows"?: number,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "client_import_batches_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"client_import_rows": {
                  Row: {
                    "batch_id": string,"chunk": number | null,"client_id": string | null,"created_at": string,"created_by": string | null,"data": NonNullable<Json>,"duplicate_of": (string)[] | null,"errors": NonNullable<Json>,"id": string,"row_number": number,"status": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "batch_id": string,"chunk"?: number | null,"client_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"data"?: NonNullable<Json>,"duplicate_of"?: (string)[] | null,"errors"?: NonNullable<Json>,"id"?: string,"row_number": number,"status": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "batch_id"?: string,"chunk"?: number | null,"client_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"data"?: NonNullable<Json>,"duplicate_of"?: (string)[] | null,"errors"?: NonNullable<Json>,"id"?: string,"row_number"?: number,"status"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "client_import_rows_batch_id_tenant_id_fkey"
      columns: ["batch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "client_import_batches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "client_import_rows_client_id_tenant_id_fkey"
      columns: ["client_id","tenant_id"]
isOneToOne: false
      referencedRelation: "clients"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "client_import_rows_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"client_notes": {
                  Row: {
                    "client_id": string,"content": string,"created_at": string,"created_by": string | null,"id": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "client_id": string,"content": string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "client_id"?: string,"content"?: string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "client_notes_client_id_tenant_id_fkey"
      columns: ["client_id","tenant_id"]
isOneToOne: false
      referencedRelation: "clients"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "client_notes_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"clients": {
                  Row: {
                    "alerts": string | null,"allergies": string | null,"anonymized_at": string | null,"blocked_reason": string | null,"created_at": string,"created_by": string | null,"date_of_birth": string | null,"email": string | null,"first_name": string,"first_name_alt": string | null,"gender": string | null,"id": string,"import_batch_id": string | null,"import_row_number": number | null,"is_blocked": boolean,"is_deleted": boolean,"last_name": string | null,"last_name_alt": string | null,"merged_into": string | null,"phone": string | null,"preferred_language": string | null,"search_text": string | null,"source": string | null,"tags": NonNullable<Json>,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "alerts"?: string | null,"allergies"?: string | null,"anonymized_at"?: string | null,"blocked_reason"?: string | null,"created_at"?: string,"created_by"?: string | null,"date_of_birth"?: string | null,"email"?: string | null,"first_name": string,"first_name_alt"?: string | null,"gender"?: string | null,"id"?: string,"import_batch_id"?: string | null,"import_row_number"?: number | null,"is_blocked"?: boolean,"is_deleted"?: boolean,"last_name"?: string | null,"last_name_alt"?: string | null,"merged_into"?: string | null,"phone"?: string | null,"preferred_language"?: string | null,"search_text"?: never,"source"?: string | null,"tags"?: NonNullable<Json>,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "alerts"?: string | null,"allergies"?: string | null,"anonymized_at"?: string | null,"blocked_reason"?: string | null,"created_at"?: string,"created_by"?: string | null,"date_of_birth"?: string | null,"email"?: string | null,"first_name"?: string,"first_name_alt"?: string | null,"gender"?: string | null,"id"?: string,"import_batch_id"?: string | null,"import_row_number"?: number | null,"is_blocked"?: boolean,"is_deleted"?: boolean,"last_name"?: string | null,"last_name_alt"?: string | null,"merged_into"?: string | null,"phone"?: string | null,"preferred_language"?: string | null,"search_text"?: never,"source"?: string | null,"tags"?: NonNullable<Json>,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "clients_import_batch_fk"
      columns: ["import_batch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "client_import_batches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "clients_merged_into_tenant_id_fkey"
      columns: ["merged_into","tenant_id"]
isOneToOne: false
      referencedRelation: "clients"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "clients_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"closed_periods": {
                  Row: {
                    "branch_id": string,"created_at": string,"ends_on": string,"id": string,"name_ar": string | null,"name_en": string | null,"starts_on": string,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"ends_on": string,"id"?: string,"name_ar"?: string | null,"name_en"?: string | null,"starts_on": string,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"ends_on"?: string,"id"?: string,"name_ar"?: string | null,"name_en"?: string | null,"starts_on"?: string,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "closed_periods_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    }
                  ]
                },"currencies": {
                  Row: {
                    "code": string,"is_active": boolean,"minor_exponent": number,"name_ar": string,"name_en": string,"symbol": string | null
                  }
                  Insert: {
                    "code": string,"is_active"?: boolean,"minor_exponent": number,"name_ar": string,"name_en": string,"symbol"?: string | null
                  }
                  Update: {
                    "code"?: string,"is_active"?: boolean,"minor_exponent"?: number,"name_ar"?: string,"name_en"?: string,"symbol"?: string | null
                  }
                  Relationships: [
                    
                  ]
                },"idempotency_keys": {
                  Row: {
                    "created_at": string,"function_name": string,"id": string,"key": string,"request_hash": string,"response_body": Json | null,"response_status": number | null,"status": string,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "created_at"?: string,"function_name": string,"id"?: string,"key": string,"request_hash": string,"response_body"?: Json | null,"response_status"?: number | null,"status"?: string,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "created_at"?: string,"function_name"?: string,"id"?: string,"key"?: string,"request_hash"?: string,"response_body"?: Json | null,"response_status"?: number | null,"status"?: string,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "idempotency_keys_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"invoice_counters": {
                  Row: {
                    "branch_id": string,"created_at": string,"id": string,"kind": string,"next_number": number,"tenant_id": string,"updated_at": string
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"id"?: string,"kind": string,"next_number"?: number,"tenant_id": string,"updated_at"?: string
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"id"?: string,"kind"?: string,"next_number"?: number,"tenant_id"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "invoice_counters_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    }
                  ]
                },"memberships": {
                  Row: {
                    "all_branches": boolean,"branch_id": string | null,"created_at": string,"created_by": string | null,"id": string,"is_active": boolean,"role": string,"tenant_id": string,"updated_at": string,"updated_by": string | null,"user_id": string
                  }
                  Insert: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"is_active"?: boolean,"role": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null,"user_id": string
                  }
                  Update: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"is_active"?: boolean,"role"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null,"user_id"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "memberships_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "memberships_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"plan_features": {
                  Row: {
                    "created_at": string,"feature": string,"plan_code": string
                  }
                  Insert: {
                    "created_at"?: string,"feature": string,"plan_code": string
                  }
                  Update: {
                    "created_at"?: string,"feature"?: string,"plan_code"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "plan_features_plan_code_fkey"
      columns: ["plan_code"]
isOneToOne: false
      referencedRelation: "plans"
      referencedColumns: ["code"]
    }
                  ]
                },"plans": {
                  Row: {
                    "code": string,"created_at": string,"is_active": boolean,"name_ar": string,"name_en": string,"updated_at": string
                  }
                  Insert: {
                    "code": string,"created_at"?: string,"is_active"?: boolean,"name_ar": string,"name_en": string,"updated_at"?: string
                  }
                  Update: {
                    "code"?: string,"created_at"?: string,"is_active"?: boolean,"name_ar"?: string,"name_en"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    
                  ]
                },"profiles": {
                  Row: {
                    "avatar_url": string | null,"created_at": string,"full_name": string,"id": string,"locale": string,"phone": string | null,"updated_at": string
                  }
                  Insert: {
                    "avatar_url"?: string | null,"created_at"?: string,"full_name": string,"id": string,"locale"?: string,"phone"?: string | null,"updated_at"?: string
                  }
                  Update: {
                    "avatar_url"?: string | null,"created_at"?: string,"full_name"?: string,"id"?: string,"locale"?: string,"phone"?: string | null,"updated_at"?: string
                  }
                  Relationships: [
                    
                  ]
                },"service_branch_overrides": {
                  Row: {
                    "branch_id": string,"buffer_after_minutes": number | null,"buffer_before_minutes": number | null,"created_at": string,"created_by": string | null,"duration_minutes": number | null,"id": string,"is_enabled": boolean,"price_minor": number | null,"service_id": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "branch_id": string,"buffer_after_minutes"?: number | null,"buffer_before_minutes"?: number | null,"created_at"?: string,"created_by"?: string | null,"duration_minutes"?: number | null,"id"?: string,"is_enabled"?: boolean,"price_minor"?: number | null,"service_id": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "branch_id"?: string,"buffer_after_minutes"?: number | null,"buffer_before_minutes"?: number | null,"created_at"?: string,"created_by"?: string | null,"duration_minutes"?: number | null,"id"?: string,"is_enabled"?: boolean,"price_minor"?: number | null,"service_id"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "service_branch_overrides_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_branch_overrides_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_effective_values"
      referencedColumns: ["service_id","tenant_id"]
    },{
      foreignKeyName: "service_branch_overrides_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "services"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_branch_overrides_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"service_categories": {
                  Row: {
                    "created_at": string,"created_by": string | null,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string | null,"sort_order": number,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "created_at"?: string,"created_by"?: string | null,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "created_at"?: string,"created_by"?: string | null,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"sort_order"?: number,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "service_categories_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"service_staff": {
                  Row: {
                    "branch_id": string,"created_at": string,"created_by": string | null,"id": string,"service_id": string,"staff_id": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"service_id": string,"staff_id": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"service_id"?: string,"staff_id"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "service_staff_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_effective_values"
      referencedColumns: ["service_id","tenant_id"]
    },{
      foreignKeyName: "service_staff_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "services"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_staff_id_branch_id_fkey"
      columns: ["staff_id","branch_id"]
isOneToOne: false
      referencedRelation: "staff_branch_assignments"
      referencedColumns: ["staff_id","branch_id"]
    },{
      foreignKeyName: "service_staff_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"services": {
                  Row: {
                    "buffer_after_minutes": number,"buffer_before_minutes": number,"category_id": string,"created_at": string,"created_by": string | null,"description_ar": string | null,"description_en": string | null,"duration_minutes": number,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string | null,"price_minor": number,"search_text": string | null,"sort_order": number,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "buffer_after_minutes"?: number,"buffer_before_minutes"?: number,"category_id": string,"created_at"?: string,"created_by"?: string | null,"description_ar"?: string | null,"description_en"?: string | null,"duration_minutes": number,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"price_minor": number,"search_text"?: never,"sort_order"?: number,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "buffer_after_minutes"?: number,"buffer_before_minutes"?: number,"category_id"?: string,"created_at"?: string,"created_by"?: string | null,"description_ar"?: string | null,"description_en"?: string | null,"duration_minutes"?: number,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string | null,"price_minor"?: number,"search_text"?: never,"sort_order"?: number,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "services_category_id_tenant_id_fkey"
      columns: ["category_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_categories"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "services_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"settings": {
                  Row: {
                    "all_branches": boolean,"branch_id": string | null,"created_at": string,"created_by": string | null,"id": string,"key": string,"tenant_id": string,"updated_at": string,"updated_by": string | null,"value": NonNullable<Json>
                  }
                  Insert: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"key": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null,"value": NonNullable<Json>
                  }
                  Update: {
                    "all_branches"?: boolean,"branch_id"?: string | null,"created_at"?: string,"created_by"?: string | null,"id"?: string,"key"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null,"value"?: NonNullable<Json>
                  }
                  Relationships: [
                    {
      foreignKeyName: "settings_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "settings_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"shifts": {
                  Row: {
                    "branch_id": string,"created_at": string,"created_by": string | null,"ends_at": string,"id": string,"staff_id": string,"starts_at": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"created_by"?: string | null,"ends_at": string,"id"?: string,"staff_id": string,"starts_at": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"created_by"?: string | null,"ends_at"?: string,"id"?: string,"staff_id"?: string,"starts_at"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "shifts_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "shifts_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "shifts_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"staff_branch_assignments": {
                  Row: {
                    "branch_id": string,"created_at": string,"created_by": string | null,"id": string,"is_bookable": boolean,"is_default": boolean,"staff_id": string,"tenant_id": string,"updated_at": string,"updated_by": string | null
                  }
                  Insert: {
                    "branch_id": string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"is_bookable"?: boolean,"is_default"?: boolean,"staff_id": string,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Update: {
                    "branch_id"?: string,"created_at"?: string,"created_by"?: string | null,"id"?: string,"is_bookable"?: boolean,"is_default"?: boolean,"staff_id"?: string,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "staff_branch_assignments_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "staff_branch_assignments_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "staff_branch_assignments_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"staff_members": {
                  Row: {
                    "created_at": string,"created_by": string | null,"email": string | null,"full_name_ar": string | null,"full_name_en": string | null,"id": string,"is_active": boolean,"is_bookable": boolean,"job_title_ar": string | null,"job_title_en": string | null,"phone": string | null,"search_text": string | null,"tenant_id": string,"updated_at": string,"updated_by": string | null,"user_id": string | null
                  }
                  Insert: {
                    "created_at"?: string,"created_by"?: string | null,"email"?: string | null,"full_name_ar"?: string | null,"full_name_en"?: string | null,"id"?: string,"is_active"?: boolean,"is_bookable"?: boolean,"job_title_ar"?: string | null,"job_title_en"?: string | null,"phone"?: string | null,"search_text"?: never,"tenant_id": string,"updated_at"?: string,"updated_by"?: string | null,"user_id"?: string | null
                  }
                  Update: {
                    "created_at"?: string,"created_by"?: string | null,"email"?: string | null,"full_name_ar"?: string | null,"full_name_en"?: string | null,"id"?: string,"is_active"?: boolean,"is_bookable"?: boolean,"job_title_ar"?: string | null,"job_title_en"?: string | null,"phone"?: string | null,"search_text"?: never,"tenant_id"?: string,"updated_at"?: string,"updated_by"?: string | null,"user_id"?: string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "staff_members_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"tenants": {
                  Row: {
                    "created_at": string,"currency_code": string,"default_locale": string,"id": string,"is_active": boolean,"name_ar": string | null,"name_en": string,"plan": string,"slug": string,"updated_at": string
                  }
                  Insert: {
                    "created_at"?: string,"currency_code"?: string,"default_locale"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en": string,"plan"?: string,"slug": string,"updated_at"?: string
                  }
                  Update: {
                    "created_at"?: string,"currency_code"?: string,"default_locale"?: string,"id"?: string,"is_active"?: boolean,"name_ar"?: string | null,"name_en"?: string,"plan"?: string,"slug"?: string,"updated_at"?: string
                  }
                  Relationships: [
                    {
      foreignKeyName: "tenants_currency_code_fkey"
      columns: ["currency_code"]
isOneToOne: false
      referencedRelation: "currencies"
      referencedColumns: ["code"]
    },{
      foreignKeyName: "tenants_plan_fkey"
      columns: ["plan"]
isOneToOne: false
      referencedRelation: "plans"
      referencedColumns: ["code"]
    }
                  ]
                }
          }
          Views: {
            "service_effective_values": {
                  Row: {
                    "branch_id": string | null,"buffer_after_minutes": number | null,"buffer_before_minutes": number | null,"category_id": string | null,"duration_minutes": number | null,"has_override": boolean | null,"is_enabled": boolean | null,"name_ar": string | null,"name_en": string | null,"price_minor": number | null,"service_id": string | null,"tenant_id": string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "services_category_id_tenant_id_fkey"
      columns: ["category_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_categories"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "services_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"service_eligible_staff": {
                  Row: {
                    "branch_id": string | null,"full_name_ar": string | null,"full_name_en": string | null,"service_id": string | null,"staff_id": string | null,"tenant_id": string | null
                  }
                  Relationships: [
                    {
      foreignKeyName: "service_staff_branch_id_tenant_id_fkey"
      columns: ["branch_id","tenant_id"]
isOneToOne: false
      referencedRelation: "branches"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "service_effective_values"
      referencedColumns: ["service_id","tenant_id"]
    },{
      foreignKeyName: "service_staff_service_id_tenant_id_fkey"
      columns: ["service_id","tenant_id"]
isOneToOne: false
      referencedRelation: "services"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_staff_id_branch_id_fkey"
      columns: ["staff_id","branch_id"]
isOneToOne: false
      referencedRelation: "staff_branch_assignments"
      referencedColumns: ["staff_id","branch_id"]
    },{
      foreignKeyName: "service_staff_staff_id_tenant_id_fkey"
      columns: ["staff_id","tenant_id"]
isOneToOne: false
      referencedRelation: "staff_members"
      referencedColumns: ["id","tenant_id"]
    },{
      foreignKeyName: "service_staff_tenant_id_fkey"
      columns: ["tenant_id"]
isOneToOne: false
      referencedRelation: "tenants"
      referencedColumns: ["id"]
    }
                  ]
                },"staff_client_cards": {
                  Row: {
                    "alerts": string | null,"allergies": string | null,"first_name": string | null,"first_name_alt": string | null,"has_safety_flags": boolean | null,"id": string | null,"last_name": string | null,"last_name_alt": string | null,"phone": string | null,"tenant_id": string | null
                  }
                  Relationships: [
                    
                  ]
                }
          }
          Functions: {
            "anonymize_client":
{ Args: { "p_actor": string,"p_client_id": string,"p_tenant_id": string }; Returns: Json
                           },
"apply_membership_change":
{ Args: { "p_action": string,"p_actor": string,"p_branch_id"?: string,"p_membership_id"?: string,"p_role"?: string,"p_tenant_id": string,"p_user_id"?: string }; Returns: string
                           },
"appointment_transition_kind":
{ Args: { "p_from": string,"p_to": string }; Returns: string
                           },
"archive_branch":
{ Args: { "p_branch_id": string }; Returns: undefined
                           },
"attach_appointment_client":
{ Args: { "p_actor": string,"p_appointment_id": string,"p_client_id": string,"p_tenant_id": string }; Returns: Json
                           },
"authorize_branch":
{ Args: { "p_branch_id": string,"p_roles": (string)[] }; Returns: string
                           },
"authorize_tenant_owner":
{ Args: { "p_tenant_id": string }; Returns: undefined
                           },
"blocked_time_actor_may_write":
{ Args: { "p_actor": string,"p_all_branches": boolean,"p_branch_id": string,"p_staff_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"blocked_time_check_conflicts":
{ Args: { "p_ends_at": string,"p_ignore_id": string,"p_staff_id": string,"p_starts_at": string }; Returns: undefined
                           },
"blocked_time_check_values":
{ Args: { "p_blocked_time_type_id": string,"p_ends_at": string,"p_starts_at": string,"p_tenant_id": string }; Returns: undefined
                           },
"book_appointment":
{ Args: { "p_actor": string,"p_branch_id": string,"p_client_id": string,"p_items": Json,"p_notes"?: string,"p_override_reason"?: string,"p_overrides"?: (string)[],"p_tenant_id": string }; Returns: Json
                           },
"booking_actor_has_role":
{ Args: { "p_actor": string,"p_branch_id": string,"p_roles": (string)[],"p_tenant_id": string }; Returns: boolean
                           },
"booking_available_slots":
{ Args: { "p_actor": string,"p_branch_id": string,"p_date": string,"p_held_items"?: Json,"p_ignore_appointment_id"?: string,"p_service_id": string,"p_staff_ids"?: (string)[],"p_tenant_id": string }; Returns: {
              "ends_at": string,"staff_id": string,"starts_at": string
            }[]
                           },
"booking_check_client":
{ Args: { "p_client_id": string,"p_tenant_id": string }; Returns: undefined
                           },
"booking_check_conflicts":
{ Args: { "p_busy": unknown,"p_ignore_appointment_id": string,"p_staff_id": string }; Returns: undefined
                           },
"booking_check_override_gate":
{ Args: { "p_overrides": (string)[],"p_violations": Json }; Returns: undefined
                           },
"booking_check_override_request":
{ Args: { "p_actor": string,"p_branch_id": string,"p_overrides": (string)[],"p_tenant_id": string }; Returns: undefined
                           },
"booking_check_self_overlap":
{ Args: { "p_items": Json }; Returns: undefined
                           },
"booking_lock_appointment":
{ Args: { "p_appointment_id": string,"p_extra_staff": (string)[],"p_tenant_id": string }; Returns: {
              "branch_id": string,
"cancellation_note": string | null,
"cancellation_reason_id": string | null,
"cancelled_at": string | null,
"cancelled_by": string | null,
"client_id": string | null,
"created_at": string,
"created_by": string | null,
"id": string,
"notes": string | null,
"ref_number": string,
"scheduled_end": string,
"scheduled_start": string,
"status": string,
"tenant_id": string,
"updated_at": string,
"updated_by": string | null
            }
                          SetofOptions: {
        from: "*"
        to: "appointments"
        isOneToOne: true
        isSetofReturn: false
      } },
"booking_lock_staff":
{ Args: { "p_staff_ids": (string)[] }; Returns: undefined
                           },
"booking_soft_rule_violations":
{ Args: { "p_branch_id": string,"p_busy": unknown,"p_staff_id": string }; Returns: (string)[]
                           },
"branch_open_ranges":
{ Args: { "p_branch_id": string,"p_from": string,"p_to": string }; Returns: unknown
                           },
"branch_staff_schedule":
{ Args: { "p_branch_id": string,"p_from": string,"p_tenant_id": string,"p_to": string }; Returns: {
              "all_branches": boolean,"blocked_time_type_id": string,"branch_id": string,"ends_at": string,"entry_id": string,"entry_type": string,"notes": string,"staff_id": string,"starts_at": string
            }[]
                           },
"can_grant_role":
{ Args: { "p_actor": string,"p_branch_id": string,"p_role": string,"p_tenant_id": string }; Returns: boolean
                           },
"cancel_appointment":
{ Args: { "p_actor": string,"p_appointment_id": string,"p_cancellation_reason_id": string,"p_note"?: string,"p_tenant_id": string }; Returns: Json
                           },
"catalogue_actor_is_owner":
{ Args: { "p_actor": string,"p_tenant_id": string }; Returns: boolean
                           },
"catalogue_actor_manages_branch":
{ Args: { "p_actor": string,"p_branch_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"client_actor_has_role":
{ Args: { "p_actor": string,"p_roles": (string)[],"p_tenant_id": string }; Returns: boolean
                           },
"client_import_batch_summary":
{ Args: { "p_batch": Database["public"]['Tables']["client_import_batches"]['Row'] }; Returns: Json
                           },
"client_import_read":
{ Args: { "p_qty"?: number,"p_vt"?: number }; Returns: {
              "batch_id": string,"chunk": number,"msg_id": number,"read_ct": number
            }[]
                           },
"client_is_bookable":
{ Args: { "p_client_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"client_name_key":
{ Args: { "p_first": string,"p_last": string }; Returns: string
                           },
"client_personal_audit_keys":
{ Args: Record<PropertyKey, never>; Returns: (string)[]
                           },
"client_tags":
{ Args: { "p_tenant_id": string }; Returns: {
              "client_count": number,"tag": string
            }[]
                           },
"colleague_profiles":
{ Args: { "p_tenant_id": string }; Returns: {
              "avatar_url": string,"full_name": string,"id": string
            }[]
                           },
"copy_shift_week":
{ Args: { "p_actor": string,"p_branch_id": string,"p_replace": boolean,"p_source_week": string,"p_staff_ids": (string)[],"p_target_week": string,"p_tenant_id": string }; Returns: Json
                           },
"create_blocked_time":
{ Args: { "p_all_branches": boolean,"p_blocked_time_type_id": string,"p_branch_id": string,"p_ends_at": string,"p_notes"?: string,"p_staff_id": string,"p_starts_at": string,"p_tenant_id": string }; Returns: string
                           },
"create_branch":
{ Args: { "p_branch": Json,"p_hours"?: Json,"p_tenant_id": string }; Returns: string
                           },
"create_client":
{ Args: { "p_client": Json,"p_proceeded_duplicate_ids"?: (string)[],"p_tenant_id": string }; Returns: string
                           },
"create_client_import_batch":
{ Args: { "p_actor": string,"p_batch_key": string,"p_file_name": string,"p_policy": string,"p_rows": Json,"p_tenant_id": string }; Returns: Json
                           },
"current_branch_scope":
{ Args: { "p_tenant_id": string }; Returns: string[]
                           },
"current_staff_appointment_ids":
{ Args: Record<PropertyKey, never>; Returns: string[]
                           },
"current_staff_ids":
{ Args: Record<PropertyKey, never>; Returns: string[]
                           },
"current_tenant_ids":
{ Args: Record<PropertyKey, never>; Returns: string[]
                           },
"default_branch_hours":
{ Args: Record<PropertyKey, never>; Returns: Json
                           },
"delete_blocked_time":
{ Args: { "p_id": string,"p_tenant_id": string }; Returns: undefined
                           },
"delete_closed_period":
{ Args: { "p_id": string }; Returns: undefined
                           },
"find_client_duplicates":
{ Args: { "p_client": Json,"p_exclude_id"?: string,"p_tenant_id": string }; Returns: {
              "email": string,"first_name": string,"first_name_alt": string,"id": string,"is_blocked": boolean,"last_name": string,"last_name_alt": string,"match_email": boolean,"match_name": boolean,"match_phone": boolean,"phone": string
            }[]
                           },
"find_client_duplicates_batch":
{ Args: { "p_actor": string,"p_rows": Json,"p_tenant_id": string }; Returns: {
              "client_ids": (string)[],"row_number": number
            }[]
                           },
"find_user_id_by_email":
{ Args: { "p_email": string }; Returns: string
                           },
"has_tenant_role":
{ Args: { "p_branch_id": string,"p_roles": (string)[],"p_tenant_id": string }; Returns: boolean
                           },
"has_tenant_role_any_branch":
{ Args: { "p_roles": (string)[],"p_tenant_id": string }; Returns: boolean
                           },
"holds_membership_authority":
{ Args: { "p_actor": string,"p_branch_id": string,"p_role": string,"p_tenant_id": string }; Returns: boolean
                           },
"holds_role_in_tenant":
{ Args: { "p_roles": (string)[],"p_tenant_id": string }; Returns: boolean
                           },
"is_client_tag_array":
{ Args: { "p_tags": Json }; Returns: boolean
                           },
"is_valid_timezone":
{ Args: { "p_timezone": string }; Returns: boolean
                           },
"jsonb_text_array":
{ Args: { "p_value": Json }; Returns: (string)[]
                           },
"kick_client_import_consumer":
{ Args: Record<PropertyKey, never>; Returns: number
                           },
"link_staff_login":
{ Args: { "p_actor": string,"p_staff_id": string,"p_tenant_id": string,"p_user_id": string }; Returns: undefined
                           },
"list_tenant_members":
{ Args: { "p_tenant_id": string }; Returns: {
              "all_branches": boolean,"branch_id": string,"created_at": string,"email": string,"full_name": string,"invite_pending": boolean,"is_active": boolean,"membership_id": string,"role": string,"user_id": string
            }[]
                           },
"match_client_duplicates":
{ Args: { "p_inputs": Json,"p_tenant_id": string }; Returns: {
              "id": string,"match_email": boolean,"match_name": boolean,"match_phone": boolean,"ord": number
            }[]
                           },
"my_assignments":
{ Args: { "p_tenant_id": string }; Returns: {
              "branch_id": string,"branch_is_active": boolean,"branch_name_ar": string,"branch_name_en": string,"first_day_of_week": number,"is_bookable": boolean,"is_default": boolean,"staff_id": string,"time_format": number,"timezone": string
            }[]
                           },
"next_counter_value":
{ Args: { "p_branch_id": string,"p_kind": string }; Returns: number
                           },
"normalize_search":
{ Args: { "p_value": string }; Returns: string
                           },
"process_client_import_chunk":
{ Args: { "p_max_attempts"?: number,"p_msg_id": number }; Returns: Json
                           },
"provision_branch":
{ Args: { "p_branch": Json,"p_hours": Json,"p_requested_by": string,"p_tenant_id": string }; Returns: Json
                           },
"provision_branch_core":
{ Args: { "p_branch": Json,"p_hours": Json,"p_tenant_id": string }; Returns: string
                           },
"provision_tenant":
{ Args: { "p_branch": Json,"p_owner_id": string,"p_requested_by": string,"p_tenant": Json }; Returns: Json
                           },
"record_client_duplicate_decision":
{ Args: { "p_client_id": string,"p_matched_ids": (string)[] }; Returns: undefined
                           },
"redact_audit_fields":
{ Args: { "p_fields": Json,"p_keys": (string)[] }; Returns: Json
                           },
"reorder_catalogue":
{ Args: { "p_actor": string,"p_category_id": string,"p_ids": (string)[],"p_kind": string,"p_tenant_id": string }; Returns: undefined
                           },
"replace_branch_hours":
{ Args: { "p_branch_id": string,"p_hours": Json }; Returns: undefined
                           },
"reschedule_appointment":
{ Args: { "p_actor": string,"p_appointment_id": string,"p_items": Json,"p_override_reason"?: string,"p_overrides"?: (string)[],"p_target_branch_id": string,"p_tenant_id": string }; Returns: Json
                           },
"resolve_service":
{ Args: { "p_branch_id": string,"p_service_id": string }; Returns: {
              "branch_id": string,"buffer_after_minutes": number,"buffer_before_minutes": number,"duration_minutes": number,"is_enabled": boolean,"price_minor": number,"service_id": string,"service_name_ar": string,"service_name_en": string,"tenant_id": string
            }[]
                           },
"restore_branch":
{ Args: { "p_branch_id": string }; Returns: undefined
                           },
"seed_tenant_catalogues":
{ Args: { "p_tenant_id": string }; Returns: undefined
                           },
"set_appointment_notes":
{ Args: { "p_actor": string,"p_appointment_id": string,"p_notes": string,"p_tenant_id": string }; Returns: Json
                           },
"set_appointment_status":
{ Args: { "p_actor": string,"p_appointment_id": string,"p_override"?: boolean,"p_reason"?: string,"p_status": string,"p_tenant_id": string }; Returns: Json
                           },
"set_blocked_time_type_active":
{ Args: { "p_id": string,"p_is_active": boolean }; Returns: undefined
                           },
"set_cancellation_reason_active":
{ Args: { "p_id": string,"p_is_active": boolean }; Returns: undefined
                           },
"set_client_blocked":
{ Args: { "p_actor": string,"p_blocked": boolean,"p_client_id": string,"p_reason"?: string,"p_tenant_id": string }; Returns: Json
                           },
"soft_delete_client":
{ Args: { "p_actor": string,"p_client_id": string,"p_tenant_id": string }; Returns: Json
                           },
"staff_actor_has_authority":
{ Args: { "p_actor": string,"p_staff_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"staff_actor_is_tenant_wide":
{ Args: { "p_actor": string,"p_tenant_id": string }; Returns: boolean
                           },
"staff_actor_manages_branch":
{ Args: { "p_actor": string,"p_branch_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"staff_assigned_at":
{ Args: { "p_branch_id": string,"p_staff_id": string }; Returns: boolean
                           },
"staff_in_caller_branches":
{ Args: { "p_roles": (string)[],"p_staff_id": string,"p_tenant_id": string }; Returns: boolean
                           },
"staff_login_status":
{ Args: { "p_staff_id": string,"p_tenant_id": string }; Returns: {
              "invite_pending": boolean,"login_email": string,"user_id": string
            }[]
                           },
"staff_schedulable_at":
{ Args: { "p_branch_id": string,"p_staff_id": string }; Returns: boolean
                           },
"staff_visible_clients":
{ Args: Record<PropertyKey, never>; Returns: {
              "alerts": string,"allergies": string,"first_name": string,"first_name_alt": string,"has_safety_flags": boolean,"id": string,"last_name": string,"last_name_alt": string,"phone": string,"tenant_id": string
            }[]
                           },
"tenant_currency_locked":
{ Args: { "p_tenant_id": string }; Returns: boolean
                           },
"tenant_has_feature":
{ Args: { "p_feature": string,"p_tenant_id": string }; Returns: boolean
                           },
"update_blocked_time":
{ Args: { "p_blocked_time_type_id": string,"p_ends_at": string,"p_id": string,"p_notes"?: string,"p_starts_at": string,"p_tenant_id": string }; Returns: undefined
                           },
"update_branch":
{ Args: { "p_branch_id": string,"p_patch": Json }; Returns: undefined
                           },
"update_tenant_details":
{ Args: { "p_patch": Json,"p_tenant_id": string }; Returns: undefined
                           },
"upsert_blocked_time_type":
{ Args: { "p_color": string,"p_id"?: string,"p_name_ar": string,"p_name_en": string,"p_sort_order"?: number,"p_tenant_id": string }; Returns: string
                           },
"upsert_cancellation_reason":
{ Args: { "p_id"?: string,"p_name_ar": string,"p_name_en": string,"p_sort_order"?: number,"p_tenant_id": string }; Returns: string
                           },
"upsert_closed_period":
{ Args: { "p_branch_id": string,"p_ends_on": string,"p_id"?: string,"p_name_ar": string,"p_name_en": string,"p_starts_on": string }; Returns: string
                           },
"upsert_service":
{ Args: { "p_actor": string,"p_service": Json,"p_tenant_id": string }; Returns: string
                           },
"upsert_staff_member":
{ Args: { "p_actor": string,"p_staff": Json,"p_tenant_id": string }; Returns: string
                           },
"write_branch_hours":
{ Args: { "p_branch_id": string,"p_hours": Json,"p_tenant_id": string }; Returns: undefined
                           }
          }
          Enums: {
            [_ in never]: never
          }
          CompositeTypes: {
            [_ in never]: never
          }
        }
}

type DatabaseWithoutInternals = Omit<Database, '__InternalSupabase'>

type DefaultSchema = DatabaseWithoutInternals[Extract<keyof Database, "public">]

export type Tables<
  DefaultSchemaTableNameOrOptions extends
    | keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
        DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? (DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"] &
      DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Views"])[TableName] extends {
      Row: infer R
    }
    ? R
    : never
  : DefaultSchemaTableNameOrOptions extends keyof (DefaultSchema["Tables"] & DefaultSchema["Views"])
  ? (DefaultSchema["Tables"] & DefaultSchema["Views"])[DefaultSchemaTableNameOrOptions] extends {
      Row: infer R
    }
    ? R
    : never
  : never

export type TablesInsert<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Insert: infer I
    }
    ? I
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Insert: infer I
    }
    ? I
    : never
  : never

export type TablesUpdate<
  DefaultSchemaTableNameOrOptions extends
    | keyof DefaultSchema["Tables"]
    | { schema: keyof DatabaseWithoutInternals },
  TableName extends DefaultSchemaTableNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"]
    : never = never
> = DefaultSchemaTableNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaTableNameOrOptions["schema"]]["Tables"][TableName] extends {
      Update: infer U
    }
    ? U
    : never
  : DefaultSchemaTableNameOrOptions extends keyof DefaultSchema["Tables"]
  ? DefaultSchema["Tables"][DefaultSchemaTableNameOrOptions] extends {
      Update: infer U
    }
    ? U
    : never
  : never

export type Enums<
  DefaultSchemaEnumNameOrOptions extends
    | keyof DefaultSchema["Enums"]
    | { schema: keyof DatabaseWithoutInternals },
  EnumName extends DefaultSchemaEnumNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"]
    : never = never
> = DefaultSchemaEnumNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[DefaultSchemaEnumNameOrOptions["schema"]]["Enums"][EnumName]
  : DefaultSchemaEnumNameOrOptions extends keyof DefaultSchema["Enums"]
  ? DefaultSchema["Enums"][DefaultSchemaEnumNameOrOptions]
  : never

export type CompositeTypes<
  PublicCompositeTypeNameOrOptions extends
    | keyof DefaultSchema["CompositeTypes"]
    | { schema: keyof DatabaseWithoutInternals },
  CompositeTypeName extends PublicCompositeTypeNameOrOptions extends {
    schema: keyof DatabaseWithoutInternals
  }
    ? keyof DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"]
    : never = never
> = PublicCompositeTypeNameOrOptions extends { schema: keyof DatabaseWithoutInternals }
  ? DatabaseWithoutInternals[PublicCompositeTypeNameOrOptions["schema"]]["CompositeTypes"][CompositeTypeName]
  : PublicCompositeTypeNameOrOptions extends keyof DefaultSchema["CompositeTypes"]
  ? DefaultSchema["CompositeTypes"][PublicCompositeTypeNameOrOptions]
  : never

export const Constants = {
  "graphql_public": {
          Enums: {
            
          }
        },"public": {
          Enums: {
            
          }
        }
} as const
A new version of Supabase CLI is available: v2.120.0 (currently installed v2.119.0)
We recommend updating regularly for new features and bug fixes: https://supabase.com/docs/guides/cli/getting-started#updating-the-supabase-cli
